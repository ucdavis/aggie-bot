#!/usr/bin/env ruby

# DSS ChatBot
# Version 0.62 2016-06-02
# Written by Christopher Thielen <cmthielen@ucdavis.edu>

require 'rubygems'
require 'bundler/setup'
require 'daemons'
require 'logger'
require 'yaml'
require 'cgi'
require 'slack-ruby-client'
require './slack-commands'

# Store the current working directory as Daemons.run_proc() will change it
$cwd = Dir.getwd

# 'Daemonize' the process (see 'daemons' gem for more information)
Daemons.run_proc('dss-chatbot.rb') do
  # Keep a log file (auto-rotate at 1 MB, keep 10 rotations)
  @logger = logger = Logger.new($cwd + '/dss-chatbot.log', 10, 1024000)

  logger.info "DSS ChatBot started at #{Time.now}"

  # Load sensitive settings from config/*
  settings_file = $cwd + '/config/settings.yml'
  if File.file?(settings_file)
    $SETTINGS = YAML.load_file(settings_file)
    logger.info "Settings loaded."
  else
    $stderr.puts "You need to set up #{settings_file} before running this script."
    logger.error "DSS ChatBot could not start because #{settings_file} does not exist. See config/settings.example.yml."
    exit
  end

  # Set up Slack connection
  Slack.configure do |config|
    config.token = $SETTINGS['SLACK_API_TOKEN']
  end

  client = Slack::RealTime::Client.new
  client.on :hello do
    logger.info "Successfully connected, welcome '#{client.self['name']}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
  end

  client.on :close do
    logger.info "Caught close signal. Attempting to restart ..."
    EM.stop
  end

  client.on :message do |data|
    # Check if the message was sent by this chat bot ... we don't need to
    # talk to ourselves.
    self_id = client.self["id"]
    next if data["user"] == self_id

    # Check if the channel source contains local config, use global config otherwise
    currentChannel = $SETTINGS[data['channel']] ? data['channel'] : 'GLOBAL'

    # Parse the received message for valid Chat Bot commands
    if data['text']
      client.message channel: data['channel'], text: SlackBotCommand.run(data['text'])
    end
  end

  # Loop itself credit slack-ruby-bot: https://github.com/dblock/slack-ruby-bot/blob/798d1305da8569381a6cd70b181733ce405e44ce/lib/slack-ruby-bot/app.rb#L45
  loop do
    logger.info "Marking the start of the client loop!"
    begin
      client.start!
    rescue Slack::Web::Api::Error => e
      logger.error e
      case e.message
      when 'migration_in_progress'
        sleep 5 # ignore, try again
      else
        raise e
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Faraday::Error::SSLError, Faraday::ClientError => e
      logger.error e
      sleep 5 # ignore, try again
    rescue StandardError => e
      logger.error e
      raise e
    #ensure
      #client = nil
    end
  end

  logger.info "DSS ChatBot ended at #{Time.now}"
end
