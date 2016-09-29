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

  # Set up LDAP support, if enabled
  if $SETTINGS['GLOBAL']['LDAP_ENABLED']
    require 'ldap'
    load $cwd + '/commands/ldap.rb'

    logger.info "LDAP command(s) enabled."
  end

  # Set up DEVBOARD support, if enabled
  if $SETTINGS['GLOBAL']['DEVBOARD_ENABLED']
    load $cwd + '/commands/devboard.rb'

    logger.info "DevBoard command(s) enabled."
  end

  # Set up Roles Management support, if enabled
  if $SETTINGS['GLOBAL']['ROLES_ENABLED']
    require 'roles-management-api'
    load $cwd + '/commands/roles.rb'

    logger.info "Roles Management command(s) enabled."
  end

  if $SETTINGS['GLOBAL']['HOST_ENABLED']
    load $cwd + '/commands/host.rb'

    logger.info "'host' command enabled."
  end

  # Set up GitHub support, if enabled
  if $SETTINGS['GLOBAL']['GITHUB_ENABLED']
    require 'octokit'

    # Load GitHub-specific settings from config/github.yml
    github_settings_file = $cwd + '/config/github.yml'
    if File.file?(github_settings_file)
      $GITHUB_SETTINGS = YAML.load_file(github_settings_file)
      logger.info "GitHub settings loaded."
    else
      $stderr.puts "You need to set up #{github_settings_file} to enable GitHub support."
      logger.error "DSS ChatBot could not start because #{github_settings_file} does not exist. See config/github.example.yml."
      exit
    end

    load $cwd + '/commands/github.rb'

    logger.info "GitHub command(s) enabled."
  end

  # Set up the easter egg 'visioneers' command, if enabled
  if $SETTINGS['GLOBAL']['VISIONEERS_ENABLED']
    load $cwd + '/commands/visioneers.rb'

    logger.info "Nonsense command(s) enabled."
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
    if data['channel'] == $SETTINGS['DSS-IT-APPDEV']
      puts "In app dev"
    end

    if data['channel'] == 'D2HPTUNSW'
      puts "private msg"
    end
    # Check if the message was sent by this chat bot ... we don't need to
    # talk to ourselves.
    self_id = client.self["id"]
    next if data["user"] == self_id

    # Check if the channel source contains local config, use global config otherwise
    currentChannel = $SETTINGS[data['channel']] ? data['channel'] : 'GLOBAL'

    # Parse the received message for valid Chat Bot commands
    case data['text']
    when /^ldap/ then
      if $SETTINGS[currentChannel]['LDAP_ENABLED']
        client.message channel: data['channel'], text: ldap_command(data['text'])
      end
    when /^host/ then
      if $SETTINGS[currentChannel]['HOST_ENABLED']
        client.message channel: data['channel'], text: host_command(Slack::Messages::Formatting.unescape(data['text']))
      end
    when /^visioneers/ then
      if $SETTINGS[currentChannel]['VISIONEERS_ENABLED']
        client.message channel: data['channel'], text: visioneers_command
      end
    when /([\w]+)\/([\d]+)/ then # look for characters followed by / followed by numbers, e.g. dw/123
      if $SETTINGS[currentChannel]['GITHUB_ENABLED']
        github_command(data['text']).each do |message|
          client.message channel: data['channel'], text: message
        end
      end
    when /^!assignments/ then
      if $SETTINGS[currentChannel]["DEVBOARD_ENABLED"]
        client.message channel: data['channel'], text: devboard_command
      end
    #when /good morning/i then
      #greetings = ['Which in ghosts make merry on this last of dear October days? Hm ... Well, good morning!', 'Where there is no imagination, there is no horror. Good morning!', 'There are nights when the wolves are silent and only the moon howls. Good morning!', 'They that are born on Halloween shall see more than other folk. Good morning!', 'Clothes make a statement. Costumes tell a story. Good morning!', 'I see dead people. Good morning!', 'October, tuck tiny candy bars in my pockets and carve my smile into a thousand pumpkins .... Merry October, and good morning!', 'Proof of our society\'s decline is that Halloween has become a broad daylight event for many. Good morning!', 'When black cats prowl and pumpkins gleam, may luck be yours on Halloween. Good morning!', 'Look, there\'s no metaphysics on earth like chocolates. Good morning!', 'Shadows of a thousand years rise again unseen, voices whisper in the trees, "Tonight is Halloween!" Also, good morning!', 'When witches go riding, and black cats are seen, the moon laughs and whispers, ‘tis near Halloween. Good morning!', 'Hold on, man. We don\'t go anywhere with "scary," "spooky," "haunted," or "forbidden" in the title. ~From Scooby-Doo. Good morning!', 'Eat, drink and be scary. And have a good morning!']
      #greetings = ['Dobro jutro', 'Goedemorgen', 'Bonjour', 'Guten Morgen', 'Howdy', 'Buongiorno', 'Dzień dobry', 'Доброе утро', 'Habari ya asubuhi', 'Bună dimineaţa']
      #client.message channel: data['channel'], text: greetings.sample #+ "!"
    when /^roles [\S]+$/i then
      if $SETTINGS['GLOBAL']['ROLES_ENABLED']
        client.message channel: data['channel'], text: roles_command(data['text'][6..-1])
      end
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
