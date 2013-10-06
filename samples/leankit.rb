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
  conf.resource = 'LeanBot'
end

LeanKitKanban::Config.email = ENV['LEANKIT_EMAIL']
LeanKitKanban::Config.password = ENV['LEANKIT_PASSWORD']
LeanKitKanban::Config.account  = ENV['LEANKIT_ACCOUNT']
board_id = ENV['LEANKIT_BOARDID']
version_id = 0


every 30 do
  begin
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
  rescue StandardError => e
    puts e
  end
end

#monkeypatch ReXML

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
