require 'sinatra'
require 'rest-client'
require './authorization_middleware'

use Rack::Logger
use SlackAuthorizer

class Pivnetbot < Sinatra::Base
  configure do
    $stdout.sync = true

    set :keyword_hash, {}
    set :pivnetbot_slack_url, ''
    set :monitored_channels, []
    set :ignored_user_ids, []

    keywords = ENV.fetch('PIVNETBOT_KEYWORDS').split(',')
    keywords &= keywords

    puts 'Making kwhash....'
    keywords.each { |keyword| settings.keyword_hash[keyword]= 0}
    puts "kwhash is: #{settings.keyword_hash}"

    puts 'Making pivnetbot slack url...'
    settings.pivnetbot_slack_url = ENV['PIVNETBOT_SLACK_URL']
    puts "pivnetbot_slack_url is #{settings.pivnetbot_slack_url}"

    puts 'Making monitored channels...'
    settings.monitored_channels = ENV.fetch('PIVNETBOT_MONITORED_CHANNEL_IDS').split(',')
    puts "monitored_channels is #{settings.monitored_channels}"

    puts 'Making ignored_user_ids...'
    settings.ignored_user_ids = ENV.fetch('PIVNETBOT_IGNORED_USER_IDS').split(',')
    puts "ignored_user_ids is #{settings.ignored_user_ids}"

    puts 'BOT INITIALIZATION DONE'
  end

  def keywords_in_comment(comment)
    puts "In keyword_search function, kwhash is: #{settings.keyword_hash}"
    keywords = []
    comment.split.each do |word|
      keywords.push(word) if settings.keyword_hash.has_key?(word)
    end
    keywords & keywords
  end

  def process_message(params)
    puts "Channel name: #{params['channel']}"
    puts "Channel type: #{params['channel_type']}"

    channel_name = params['channel']
    user_id = params['user']

    puts "Is #{channel_name} in list #{settings.monitored_channels}: #{settings.monitored_channels.include?(channel_name)}"
    puts "Is #{user_id} in list #{settings.ignored_user_ids}: #{!settings.ignored_user_ids.include?(user_id)}"

    settings.monitored_channels.include?(channel_name) && !settings.ignored_user_ids.include?(user_id)
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

  def handle_challenge(params)
    return 'ERROR: missing parameter: "challenge"' unless params['challenge']

    puts 'Received a challenge!'
    challenge = params['challenge']
    puts "Challenge is: #{challenge}"
    challenge
  end

  def handle_message(params)
    return 'ERROR: missing parameter: "text"' unless params['text']

    puts 'Received a comment!'
    comment = params['text']
    comment = comment.split(' ').map {|s| s.gsub(/\W/, '')}.join(' ')
    keywords_found = keywords_in_comment(comment)
    puts "Found these keywords: #{keywords_found}"
    send_message_to_webhook("Lobster received this string: #{comment}")
    send_message_to_webhook("Lobster parsed these keywords: #{keywords_found}")
    keywords_found
  end

  post '*' do
    puts 'lobster received'

    params = JSON.parse(request.body.read)['event']
    puts "got some params #{params}"

    if process_message(params)
      if params['type'] == 'url_verification'
        handle_challenge(params)
      elsif params['type'] == 'message'
        handle_message(params)
      else
        "received literally any other kind of request: #{params['type']}"
      end
    end
  end
end

Pivnetbot.run!