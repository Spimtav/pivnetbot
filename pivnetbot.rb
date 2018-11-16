require 'sinatra'
require 'rest-client'
require './authorization_middleware'

use Rack::Logger
use SlackAuthorizer

class Pivnetbot < Sinatra::Base
  configure do
    $stdout.sync = true

    set :keyword_hash, {}

    keywords = ENV.fetch('PIVNETBOT_KEYWORDS').split(',')
    keywords &= keywords

    puts 'Making kwhash....'
    keywords.each { |keyword| settings.keyword_hash[keyword]= 0}
    puts "added these keywords: #{keywords}"
    puts "kwhash is: #{settings.keyword_hash}"
    puts 'finished initializing kwhash'
  end

  def keywords_in_comment(comment)
    puts "In keyword_search function, kwhash is: #{settings.keyword_hash}"
    keywords = []
    comment.split.each do |word|
      keywords.push(word) if settings.keyword_hash.has_key?(word)
    end
    keywords & keywords
  end

  def send_message_to_webhook(data)
    RestClient::Request.execute(
        method: :post,
        url: ENV['PIVNETBOT_SLACK_URL'],
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

    params = JSON.parse(request.body.read)
    puts "got some params #{params}"

    if params['type'] == 'url_verification'
      handle_challenge(params)
    elsif params['type'] == 'message'
      handle_message(params)
    else
      "received literally any other kind of request: #{params['type']}"
    end
  end
end

Pivnetbot.run!