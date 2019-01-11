require 'json'
require 'sinatra'
require 'rest-client'
require './authorization_middleware'
require './google_sheets'

use Rack::Logger
use SlackAuthorizer

class Pivnetbot < Sinatra::Base
  configure do
    $stdout.sync = true

    set :verification_token, ENV['PIVNETBOT_VERIFICATION_TOKEN']
    set :oauth_token, ENV['PIVNETBOT_OAUTH_TOKEN']
    set :keywords, ENV.fetch('PIVNETBOT_KEYWORDS').split(',')
    set :pivnetbot_slack_url, ENV['PIVNETBOT_SLACK_URL']
    set :google_sheets_credentials, ENV['PIVNETBOT_GOOGLE_SHEETS_CREDENTIALS']
    set :spreadsheet_title, ENV['PIVNETBOT_SPREADSHEET_TITLE']
    set :google_sheets_worksheet_object, GoogleSheets::initialize(settings)
  end

  def keywords_in_comment(comment)
    keywords_found = []
    comment = comment.split(' ').map {|s| s.gsub(/\W/, '')}.join(' ')
    comment = comment.downcase

    settings.keywords.each do |keyword|
      keywords_found.push(keyword) if comment.include?(keyword)
    end

    keywords_found & keywords_found
  end

  def should_process_message(params)
    message_subtype = params['subtype']

    message_subtype != 'bot_message'
  end

  def send_message_to_webhook(data)
    RestClient::Request.execute(
      method: :post,
      url: settings.pivnetbot_slack_url,
      payload: {text: data}.to_json,
      timeout: 10,
      headers: { content_type: 'application/json' }
    )
  end

  def get_user_profile(user_id)
    base_url = 'https://slack.com/api/users.info'
    full_url = "#{base_url}?token=#{settings.oauth_token}&user=#{user_id}"

    response = JSON.parse(RestClient::Request.execute(
        method: :get,
        url: full_url,
        timeout: 10
    ).body)

    unless response['error'].nil?
      return ''
    end
    response['user']['profile']
  end

  def get_message_permalink(message_timestamp, channel_id)
    base_url = 'https://slack.com/api/chat.getPermalink'
    full_url = "#{base_url}?token=#{settings.oauth_token}&message_ts=#{message_timestamp}&channel=#{channel_id}"

    response = JSON.parse(RestClient::Request.execute(
      method: :get,
      url: full_url,
      timeout: 10
    ).body)

    unless response['error'].nil?
      return ''
    end
    response['permalink']
  end

  def handle_challenge(params)
    return 'ERROR: missing parameter: "challenge"' unless params['challenge']

    params['challenge']
  end

  def handle_message(params)
    return 'ERROR: missing parameter: "text"' unless params['text']
    return 'ERROR: missing parameter: "ts"' unless params['ts']
    return 'ERROR: missing parameter: "channel"' unless params['channel']

    comment = params['text']
    message_timestamp = params['ts']
    channel_id = params['channel']
    keywords_found = keywords_in_comment(comment)

    if keywords_found.size > 0
      message_permalink = get_message_permalink(message_timestamp, channel_id)
      timestamp = Time.at(params['ts'].to_f)

      user_profile = get_user_profile(params['user'])
      user_name = user_profile['real_name']
      user_email = user_profile['email']

      line = [
          timestamp.strftime('%Y-%m-%d'),
          timestamp.strftime('%H:%M:%S'),
          keywords_found.join(", "),
          comment,
          user_name,
          user_email,
          message_permalink
      ]

      GoogleSheets::write_line(settings, line)
    end

    keywords_found
  end

  post '*' do
    params = JSON.parse(request.body.read)
    request.body.rewind

    params = JSON.parse(request.body.read)['event']

    if should_process_message(params)
      if params['type'] == 'url_verification'
        handle_challenge(params)
      elsif params['type'] == 'message'
        handle_message(params)
      else
        "received request type that this bot doesn't handle: #{params['type']}"
      end
    end
  end
end

Pivnetbot.run!