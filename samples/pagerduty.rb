#!/usr/bin/env ruby

require 'rubygems'
require 'jabbot'
require 'rest-client'
require 'pp'
require 'json'

configure do |conf|
  conf.login = ENV['JABBOT_LOGIN'] || 'login@server.tld'
  conf.channel = ENV['JABBOT_CHANNEL'] || 'jabbot_test'
  conf.server = ENV['JABBOT_SERVER'] || 'conference.server.tld'
  conf.password = ENV['JABBOT_PASSWORD'] || 'secret'
  conf.nick = 'DutyBot'
  conf.resource = 'DutyBot'
end

## Just print all incoming messages to stdout.
#message do |message, params|
  #puts message
#end

## Agree to certain users, no matter what they said.
#message :from => [:abcd, :efgh] do |message, params|
  #post "I agree!" => message.user
#end

## The user 'admin' can quit the bot via private message.
#query /\A!quit\Z/, :from => :admin do |message, params|
  #post "good bye! I'm going to sleep" => message.user
  #close
#end

## Same as query above, but for all users and global messages.
#message :exact => "!quit" do |message, params|
  #post "Bye Bye!"
  #close
#end

## Respond with whatever was given as the answer.
#message ".answer :me" do |message, params|
  #post "ok, the answer is: #{params[:me]}"
#end

### You need a extern Google engine
### write your own or search github.com
#message /\A!google (.+)/im do |message, params|
  #search_result = MyGoogleSearch.lookup(params.first)
  #post "Google Search for '#{params.first}':\n#{search_result}"
#end

#leave do |message, params|
  #post "and there he goes...good bye, #{message.user}"
#end

#join do |message, params|
  #post "Hi, #{message.user}. How are you?"
#end

$pagerduty = RestClient::Resource.new(
  "https://#{ENV['PAGERDUTY_ACCOUNT']}.pagerduty.com//api/v1/",
  :headers => { 
    "Authorization" => "Token token=#{ENV['PAGERDUTY_TOKEN']}",
    "Content-type" => "application/json"
  }
)
first_run = true
known_incidents = []
# rule out some resolved incidents while debugging
#known_incidents = (1..929).to_a

# list current incidents, if not already noticed
every 30 do
  if first_run
    first_run = false
    post "DutyBot is on the job!"
  end

  begin
    response =  JSON.parse($pagerduty['incidents'].get(params: {status: "triggered,acknowledged"}))

    #TODO: don't actually take resolved incidents, just debugging
    #response =  JSON.parse($pagerduty['incidents'].get(params: {status: "resolved,triggered,acknowledged"}))
    incidents = response['incidents'].map { |i| i['incident_number'] }
    new_incidents = incidents - known_incidents
    known_incidents += new_incidents
    puts "NEW #{new_incidents}"
    puts "OLD #{known_incidents}"
    response['incidents'].each do |inc|
      if new_incidents.include? inc['incident_number'].to_i
        summary = inc['trigger_summary_data']
        summary_text = summary['SERVICEDESC'] || summary['subject']
        post <<-EOM.gsub /^\s*/, ''
          New incident ##{inc['incident_number']} from #{inc['service']['name']}
          #{summary_text}
          #{inc['html_url']}
        EOM
      end
    end
  rescue StandardError => e
    puts e
  end
  
end

#monkeypatch rexml

require 'socket'
class TCPSocket
  def external_encoding
      Encoding::BINARY
  end
end

require 'rexml/source'
class REXML::IOSource
  alias_method :encoding_assign, :encoding=
  def encoding=(value)
      encoding_assign(value) if value
  end
end

begin
  # OpenSSL is optional and can be missing
  require 'openssl'
  class OpenSSL::SSL::SSLSocket
      def external_encoding
          Encoding::BINARY
      end
  end
rescue
end
