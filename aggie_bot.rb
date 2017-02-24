#!/usr/bin/env ruby

# DSS ChatBot
# Version 0.72 2017-02-24
# See AUTHORS file

LOG_FILENAME = "chatbot.log"
LOG_ROTATIONS = 10
LOG_SIZE = 1024000

CUSTOMER_LOG_FILENAME = "customers.log"
CUSTOMER_LOG_ROTATIONS = 10
CUSTOMER_LOG_SIZE = 1024000

SETTINGS_FILENAME = "settings.yml"

require 'rubygems'
require 'bundler/setup'
require 'daemons'
require 'logger'
require 'yaml'
require 'cgi'
require 'slack-ruby-client'

load './chat_bot_command.rb'

# Load settings from disk
# Returns nil if file is not found or global settings is not set up
# @param filepath - file path
def load_settings(filepath)
  if File.file?(filepath)
    settings = YAML.load_file(filepath)

    if settings["GLOBAL"] == nil
      $stderr.puts "Settings file found but missing GLOBAL section. Cannot proceed."
      $logger.error "Aggie Bot could not start because #{filepath} does not have a GLOBAL section. See example."
      return nil
    end

    $logger.info "Settings loaded from #{filepath}."
  else
    $logger.error "Aggie Bot could not start because #{filepath} does not exist. See example."
    return nil
  end

  return settings
end

# Store the current working directory as Daemons.run_proc() will change it
$cwd = Dir.getwd

# 'Daemonize' the process (see 'daemons' gem for more information)
Daemons.run_proc('aggie_bot.rb') do
  # Log errors / information to console
  $logger = Logger.new($cwd + '/' + LOG_FILENAME, LOG_ROTATIONS, LOG_SIZE)
  $logger.level = Logger::DEBUG

  # Keep a log file of users using chatbot
  $customer_log = Logger.new($cwd + '/' + CUSTOMER_LOG_FILENAME, CUSTOMER_LOG_ROTATIONS, CUSTOMER_LOG_SIZE)

  $logger.info "Aggie Bot started at #{Time.now}"

  # Load settings from disk
  $settings_file = $cwd + '/' + SETTINGS_FILENAME
  $SETTINGS = load_settings($settings_file)
  exit(-1) if $SETTINGS == nil

  # Set up chat commands plugin
  ChatBotCommand.initialize($cwd)

  # Set up Slack connection
  Slack.configure do |config|
    config.token = $SETTINGS['SLACK_API_TOKEN']
  end

  client = Slack::RealTime::Client.new

  # Register Slack::RealTime::Client event callbacks
  client.on :hello do
    $logger.info "Successfully connected, welcome '#{client.self['name']}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
  end

  client.on :close do
    $logger.warn "Caught close signal."
    EM.stop
  end

  client.on :message do |data|
    # Ignore messages from this bot
    next if data["user"] == client.self["id"]

    # True if the channel is one of the channels directly messaging chatbot
    is_dm = client.ims[data["channel"]] != nil
    
    # Parse the received message for valid Chat Bot commands
    if data["text"]
      # Parse message based on commands found in commands/*.rb
      response = ChatBotCommand.dispatch(data['text'], data['channel'], client.users[data["user"]], is_dm)

      # Send reply (if any)
      client.message(channel: data['channel'], text: response) unless response == nil
    end
  end

  client.on :group_joined do
    $logger.debug "Entered private channel, reloading data"
    ChatBotCommand.reload_channels!
  end

  # Loop itself credit slack-ruby-bot: https://github.com/dblock/slack-ruby-bot/blob/798d1305da8569381a6cd70b181733ce405e44ce/lib/slack-ruby-bot/app.rb#L45
  loop do
    $logger.debug "Client loop has started."
    begin
      client.start!
    rescue Slack::Web::Api::Error => e
      $logger.error e
      case e.message
      when 'migration_in_progress'
        sleep 5 # ignore, try again
      else
        raise e
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Faraday::Error::SSLError, Faraday::ClientError => e
      $logger.error e
      sleep 5 # ignore, try again
    rescue Slack::RealTime::Client::ClientAlreadyStartedError => e
      # We receive this exception when ChatBot is killed via ctrl+c but otherwise had no error.
      # Correct behavior is to exit.
      break
    rescue StandardError => e
      $logger.error e
      raise e
    end
  end

  $logger.info "Aggie Bot ended at #{Time.now}"
end
