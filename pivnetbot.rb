require 'sinatra'
require './authorization_middleware'

use SlackAuthorizer

class Pivnetbot < Sinatra::Base
  configure do
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

  post '*' do
    puts 'lobster received'

    params = JSON.parse(request.body.read)
    puts "got some params #{params}"

    if params['type'] && params['type'] == 'message'
      return 'Error: no message text' unless params['text']
      puts 'Received a comment!'
      comment = params['text']
      puts "Found these keywords: #{keywords_in_comment(comment)}"
    else
      puts "received literally any other kind of request: #{params['type']}"
    end

    "lobster received a request of type #{params['type']}"
  end
end

Pivnetbot.run!