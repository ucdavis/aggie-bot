#!/usr/bin/env ruby

# Aggie Bot
# Version 0.80 2018-04-04
# See AUTHORS file

LOG_FILENAME = 'chatbot.log'.freeze
LOG_ROTATIONS = 10
LOG_SIZE = 1024000

CUSTOMER_LOG_FILENAME = 'customers.log'.freeze
CUSTOMER_LOG_ROTATIONS = 10
CUSTOMER_LOG_SIZE = 1024000

SETTINGS_FILENAME = 'settings.yml'.freeze

require 'rubygems'
require 'bundler/setup'
require 'daemons'
require 'logger'
require 'yaml'
require 'cgi'
require 'slack-ruby-client'
require 'async'
require 'erb'
require 'byebug'

load './chat_bot_command.rb'

threads = []

# Load settings from disk
# Returns nil if file is not found or global settings is not set up
# @param filepath - file path
def load_settings(filepath)
  if File.file?(filepath)
    settings = YAML.load(ERB.new(File.read(filepath)).result)

    if settings['GLOBAL'].nil?
      $stderr.puts 'Settings file found but missing GLOBAL section.'
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
# Daemons.run_proc('aggie_bot.rb') do
  # Log errors / information to console
  $stdout.sync = true
  $logger = Logger.new($stdout)
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
    $logger.warn 'Caught close signal.'
    EM.stop
  end

  client.on :message do |data|
    # Ignore messages from this bot
    next if data['user'] == client.self['id']

    # ignore all bot messages
    next if data['bot_id']

    # client no longer provides channels or users, query on demand
    channel = client.web_client.conversations_info(channel: data['channel']).channel
    user = client.web_client.users_info(user: data['user']).user
    is_dm = channel.is_im

    # Parse the received message for valid Chat Bot commands
    if data['text']
      # Parse message based on commands found in commands/*.rb
      response = ChatBotCommand.dispatch(data['text'], data['channel'], user, is_dm)
      response += ">:loudspeaker:  *_@aggie_bot will stop working after March 31, 2025._* :loudspeaker:\n>To continue using the service in your channel, please remove the old bot with `/remove @aggie_bot`.\n>Then, add the new *@aggiebot* app with `/invite @aggiebot` or message <@U07QFTHM4QZ> directly.";

      if response
        # Send reply (if any)
        if data['thread_ts']
          client.message(channel: data['channel'], thread_ts: data['thread_ts'], text: response)
        else
          client.message(channel: data['channel'], text: response)
        end
      end
    end
  end

  client.on :group_joined do
    $logger.debug 'Entered private channel, reloading data'
    ChatBotCommand.reload_channels!
  end

  # Loop itself credit slack-ruby-bot: https://github.com/dblock/slack-ruby-bot/blob/798d1305da8569381a6cd70b181733ce405e44ce/lib/slack-ruby-bot/app.rb#L45
# loop do
    $logger.debug 'Client loop has started.'
    begin
      threads << client.start_async
      threads.each(&:join)
    rescue Slack::Web::Api::Error => e
      $logger.error e
      case e.message
      when 'migration_in_progress'
        sleep 5 # ignore, try again
      when 'account_inactive'
        sleep 5 # technically, we should give up, but we received this once by accident, so ...
      else
        raise e
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Faraday::Error::SSLError, Faraday::ClientError => e
      $logger.error e
      sleep 5 # ignore, try again
    rescue Slack::RealTime::Client::ClientAlreadyStartedError => e
      # We receive this exception when ChatBot is killed via ctrl+c but otherwise had no error.
      # Correct behavior is to exit.
      raise e
    rescue StandardError => e
      $logger.error e
      raise e
    end
  # end

  $logger.info "Aggie Bot ended at #{Time.now}"
# end
