#!/usr/bin/env ruby

# DSS ChatBot
# Version 0.5 2015-10-12
# Written by Christopher Thielen <cmthielen@ucdavis.edu>

require 'rubygems'
require 'bundler/setup'

require 'daemons'
require 'sysaid'
require 'logger'
require 'cgi'
require 'ldap'
require 'slack-ruby-client'
require 'roles-management-api'

# Include support for various commands
load 'commands/ldap.rb'
load 'commands/sysaid.rb'
load 'commands/visioneers.rb'
load 'commands/roles.rb'

# Set up paths here as daemonizing will change our current working directory
log_file = Dir.getwd + '/dss-chatbot.log'
settings_file = Dir.getwd + '/config/settings.yml'

Daemons.run_proc('dss-chatbot.rb') do
  # Keep a log file (auto-rotate at 1 MB, keep 10 rotations)
  logger = Logger.new(log_file, 10, 1024000)

  logger.info "DSS ChatBot started at #{Time.now}"

  # Load sensitive settings from config/*
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

  # Log into SysAid
  begin
    SysAid::login $SETTINGS['SYSAID_ACCOUNT'], $SETTINGS['SYSAID_USER'], $SETTINGS['SYSAID_PASSWORD'], $SETTINGS['SYSAID_URI']
    logger.info "Logged into SysAid."
  rescue Exception => e
    $stderr.puts "Failed to connect to SysAid: #{e}"
    logger.error "DSS ChatBot could not start because it failed to connect to SysAid. Exception: #{e}"
    exit
  end

  client = Slack::RealTime::Client.new

  client.on :hello do
    logger.info "Successfully connected, welcome '#{client.self['name']}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
  end

  client.on :message do |data|
    case data['text']
    when /sysaid/i then
      client.message channel: data['channel'], text: sysaid_command(data['text'])
    when /#[0-9]+(\s|$|\z)/ then
      client.message channel: data['channel'], text: sysaid_command(data['text'])
    when /^ldap/ then
      client.message channel: data['channel'], text: ldap_command(data['text'])
    when /^visioneers/ then
      client.message channel: data['channel'], text: visioneers_command
    when /good morning/i then
      greetings = ['Dobro jutro', 'Goedemorgen', 'Bonjour', 'Guten Morgen', 'Howdy', 'Buongiorno', 'Dzień dobry', 'Доброе утро', 'Habari ya asubuhi', 'Bună dimineaţa']
      client.message channel: data['channel'], text: greetings.sample + "!"
    when /^roles [\S]+$/i then
      client.message channel: data['channel'], text: roles_command(data['text'][6..-1])
    end
  end

  client.start!

  logger.info "DSS ChatBot ended at #{Time.now}"
end
