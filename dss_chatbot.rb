#!/usr/bin/env ruby

# DSS ChatBot
# Version 0.7 2016-11-09
# See AUTHORS file

CUSTOMER_LOG_ROTATIONS = 10
CUSTOMER_LOG_SIZE = 1024000
# Will be resolved as current working directory + "/" + SETTINGS_FILENAME
SETTINGS_FILENAME = "settings.yml"

require 'rubygems'
require 'bundler/setup'
require 'daemons'
require 'logger'
require 'yaml'
require 'cgi'
require 'slack-ruby-client'

load './chat_bot_command.rb'

# Store the current working directory as Daemons.run_proc() will change it
$cwd = Dir.getwd

# Load settings from disk
# Returns nil if file is not found or global settings is not set up
# @param filepath - file path
def load_settings(filepath)
  if File.file?(filepath)
    settings = YAML.load_file(filepath)

    if settings["GLOBAL"] == nil
      $stderr.puts "Settings file found but missing GLOBAL section. Cannot proceed."
      $logger.error "DSS ChatBot could not start because #{filepath} does not have a GLOBAL section. See example."
      return nil
    end

    $logger.info "Settings loaded from ."
  else
    #$stderr.puts "You need to set up #{filepath} before running this script."
    $logger.error "DSS ChatBot could not start because #{filepath} does not exist. See example."
    return nil
  end

  return settings
end

# 'Daemonize' the process (see 'daemons' gem for more information)
Daemons.run_proc('dss-chatbot.rb') do
  # Log errors / information to console
  $logger = Logger.new(STDOUT)

  # Keep a log file of users using chatbot
  $customer_log = Logger.new($cwd + "/chatbot-customers.log", CUSTOMER_LOG_ROTATIONS, CUSTOMER_LOG_SIZE)

  $logger.info "DSS ChatBot started at #{Time.now}"

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
    $logger.info "Caught close signal. Attempting to restart ..."
    EM.stop
  end

  client.on :message do |data|
    # Ignore messages from this bot
    next if data["user"] == client.self["id"]

    # True if the channel is one of the channels directly messaging chatbot
    is_dm = client.ims[data["channel"]] != nil
    
    # Parse the received message for valid Chat Bot commands
    if data['text']
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
    $logger.info "Marking the start of the client loop!"
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
    rescue StandardError => e
      $logger.error e
      raise e
    end
  end

  $logger.info "DSS ChatBot ended at #{Time.now}"
end
