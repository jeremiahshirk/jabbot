#!/usr/bin/env ruby

require 'rubygems'
require 'jabbot'
require 'leankitkanban'
require 'pp'

configure do |conf|
  conf.login = ENV['JABBOT_LOGIN'] || 'login@server.tld'
  conf.channel = ENV['JABBOT_CHANNEL'] || 'jabbot_test'
  conf.server = ENV['JABBOT_SERVER'] || 'conference.server.tld'
  conf.password = ENV['JABBOT_PASSWORD'] || 'secret'
  conf.nick = 'LeanBot'
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

LeanKitKanban::Config.email = ENV['LEANKIT_EMAIL']
LeanKitKanban::Config.password = ENV['LEANKIT_PASSWORD']
LeanKitKanban::Config.account  = ENV['LEANKIT_ACCOUNT']
board_id = ENV['LEANKIT_BOARDID']
version_id = 0


every 5 do
  if version_id == 0
    board = LeanKitKanban::Board.get_newer_if_exists(board_id, version_id)
    version_id = board[0]['Version']
    post "LeanBot is ready to rock. Current board version is #{version_id}"
  end
  
  last_events = LeanKitKanban::Board.get_board_history_since(board_id, version_id)[0]
  if last_events
    pp last_events
    last_events.each do |event|
      if event['CardId'] > 0 # Numerous events messages have CardId == -1
        post "#{event['Message']}"
        version_id += 1
      end
    end
  end
end
