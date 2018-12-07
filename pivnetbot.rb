require 'sinatra'
require 'rest-client'
require './authorization_middleware'
require './google_sheets'

use Rack::Logger
use SlackAuthorizer

class Pivnetbot < Sinatra::Base
  configure do
    $stdout.sync = true

    set :token, ENV['PIVNETBOT_TOKEN']
    set :keywords, ENV.fetch('PIVNETBOT_KEYWORDS').split(',')
    set :pivnetbot_slack_url, ENV['PIVNETBOT_SLACK_URL']
    set :google_sheets_credentials, ENV['PIVNETBOT_GOOGLE_SHEETS_CREDENTIALS']
    set :spreadsheet_title, ENV['PIVNETBOT_SPREADSHEET_TITLE']
    set :google_sheets_worksheet_object, GoogleSheets::initialize(settings)

    puts "keyword list is: #{settings.keywords}"
    puts "pivnetbot_slack_url is #{settings.pivnetbot_slack_url}"
    puts "google_sheets_credentials is #{settings.google_sheets_credentials}"
    puts "spreadsheet_id is #{settings.spreadsheet_title}"
    puts "Google sheets service object is: #{settings.google_sheets_worksheet_object.inspect}"

    puts 'Writing line to sheet'
    # GoogleSheets::write_line(settings, ['私', 'の', '猫', 'が', '可愛い', 'です'])

    puts 'BOT INITIALIZATION DONE'
  end

  def keywords_in_comment(comment)
    puts "In keyword_search function, keyword list is: #{settings.keywords}"
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

    puts "Is this '#{message_subtype}' a bot message: #{message_subtype == 'bot_message'}"

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

  def get_message_permalink(message_timestamp, channel_id)
    response = RestClient::Request.execute(
      method: :get,
      url: 'https://slack.com/api/chat.getPermalink',
      payload: {
        token: settings.token,
        channel: channel_id,
        message_ts: message_timestamp
      }.to_json,
      timeout: 10,
    )

    puts "Message permalink response is: #{response.inspect}"
  end

  def handle_challenge(params)
    return 'ERROR: missing parameter: "challenge"' unless params['challenge']

    puts 'Received a challenge!'
    challenge = params['challenge']
    puts "Challenge is: #{challenge}"
    challenge
  end

  def handle_message(params)
    return 'ERROR: missing parameter: "text"' unless params['text']
    return 'ERROR: missing parameter: "ts"' unless params['ts']
    return 'ERROR: missing parameter: "channel"' unless params['channel']

    puts 'Received a comment!'
    comment = params['text']
    message_timestamp = params['ts']
    channel_id = params['channel']
    keywords_found = keywords_in_comment(comment)
    puts "Found these keywords: #{keywords_found}"
    send_message_to_webhook("Lobster received this string: #{comment}")
    send_message_to_webhook("Lobster parsed these keywords: #{keywords_found}")

    message_permalink = get_message_permalink(message_timestamp, channel_id)

    line = [
      Time.at(params['ts'].to_f),
      keywords_found.join(", "),
      comment,
      message_permalink
    ]

    GoogleSheets::write_line(settings, [line])

    keywords_found
  end

  post '*' do
    puts 'lobster received'

    params = JSON.parse(request.body.read)['event']
    puts "got some params #{params}"

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