require 'sinatra'
require 'rest-client'
require './authorization_middleware'

use Rack::Logger
use SlackAuthorizer

class Pivnetbot < Sinatra::Base
  configure do
    $stdout.sync = true

    set :keywords, []
    set :pivnetbot_slack_url, ''

    puts 'Making keyword list...'
    settings.keywords = ENV.fetch('PIVNETBOT_KEYWORDS').split(',')
    puts "keyword list is: #{settings.keywords}"

    puts 'Making pivnetbot slack url...'
    settings.pivnetbot_slack_url = ENV['PIVNETBOT_SLACK_URL']
    puts "pivnetbot_slack_url is #{settings.pivnetbot_slack_url}"

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

  def process_message(params)
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
        "received request type that this bot doesn't handle: #{params['type']}"
      end
    end
  end
end

Pivnetbot.run!