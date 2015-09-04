# DSS ChatBot
# Version 0.2 2015-08-06
# Written by Christopher Thielen <cmthielen@ucdavis.edu>

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'hipchat'
require 'sysaid'
require 'logger'
require 'cgi'
require 'ldap'

SETTINGS_FILE = "config/settings.yml"
LDAP_MAX_RESULTS = 8

# Keep a log file (auto-rotate at 1 MB, keep 10 rotations)
logger = Logger.new('dss-chatbot.log', 10, 1024000)

logger.info "DSS ChatBot started at #{Time.now}"

# Load sensitive settings from config/*
if File.file?(SETTINGS_FILE)
  $SETTINGS = YAML.load_file(SETTINGS_FILE)
  logger.info "Settings loaded."
else
  $stderr.puts "You need to set up #{SETTINGS_FILE} before running this script."
  logger.error "DSS ChatBot could not start because #{SETTINGS_FILE} does not exist. See config/settings.example.yml."
  exit
end

# Set up HipChat client
hipchat_client = HipChat::Client.new($SETTINGS['HIPCHAT_API_TOKEN'])

# Log into SysAid
begin
  SysAid::login $SETTINGS['SYSAID_ACCOUNT'], $SETTINGS['SYSAID_USER'], $SETTINGS['SYSAID_PASSWORD'], $SETTINGS['SYSAID_URI']
  logger.info "Logged into SysAid."
rescue Exception => e
  $stderr.puts "Failed to connect to SysAid: #{e}"
  logger.error "DSS ChatBot could not start because it failed to connect to SysAid. Exception: #{e}"
  exit
end

# HipChat's protocol requires we provide a "capabilities document".
# See views/capabilities.erb
get '/capabilities' do
  erb :capabilities
end

post '/installable' do
  # Read the HTTP body
  request.body.rewind

  body = request.body.read

  if body.length > 0
    data = JSON.parse body

    if data["groupId"].to_s == $SETTINGS['HIPCHAT_GROUP_ID']
      logger.info "Accepted installable as it matched our group ID."
      status 200
      ""
    else
      logger.info "Rejected installable as it did not match our group ID. Attempted from group ID #{data["groupId"].to_s}"
      status 401
      ""
    end
  end
end

delete '/installable' do
  # Read the HTTP body
  request.body.rewind

  body = request.body.read

  if body.length > 0
    data = JSON.parse body
  end

  status 200
  ""
end

# HipChat will HTTP POST to this URL when a message matching our requests
# (defined by 'capabilities' above). We parse the message and communicate
# back using the HipChat API client provided by the 'hipchat' gem.
post '/webhook' do
  # Read the HTTP body
  request.body.rewind

  body = request.body.read

  if body.length > 0
    data = JSON.parse body

    # If we received valid JSON, begin parsing the message
    if data["event"] == "room_message"
      if data["item"]
        # Extract data needed to understand the message we received
        message = data["item"]["message"]["message"] # the chat text
        room_name = data["item"]["room"]["name"] # room name where it was sent
        mention_from = data["item"]["message"]["from"]["mention_name"] # 'mention-version' of the user who sent the message
        command = params[:command] #/^\/([a-zA-Z]+)/.match(message)[1]

        # We will compose our reply in reply_message
        reply_message = ""

        case command
        when 'sysaid'
          reply_message = sysaid_command(message)
        when 'ldap'
          reply_message = ldap_command(message)
        when 'visioneers'
          if(Time.now.hour < 17)
            reply_message = "There are #{((Time.new(Time.now.year, Time.now.month, Time.now.day, 17, 0, 0) - Time.now) / 60).to_i} minutes of productivity remaining in the day."
          else
            reply_message = "There are no minutes of productivity remaining in the day."
          end
        else
          logger.warn "Unknown command #{command}. Check the webhooks defined in /capabilities"
          reply_message = ""
        end

        hipchat_client[room_name].send("DSS ChatBot", reply_message, { :message_format => "html", :notify => false }) if reply_message.length > 0
      end
    end

    "" # Sinatra (our web framework) wants us to return some type of view, so return an empty string
  end
end

def sysaid_command(message)
  ticket_id = message[/\d+/] # ticket ID of the message
  link = "https://sysaid.dss.ucdavis.edu/index.jsp#/SREdit.jsp?QuickAcess&id=" + ticket_id # link template for a SysAid ticket given ID

  # Find ticket in SysAid
  ticket = SysAid::Ticket.find_by_id(ticket_id)
  if ticket.nil?
    # Ticket does not exist.
    return "Couldn't find a ticket with ID #{ticket_id}"
  else
    # Ticket exists, compose 'reply_message'
    return "<b>#{CGI.escapeHTML(ticket.title)}</b> requested by <b>#{CGI.escapeHTML(ticket.request_user)}</b>: <a href=\"#{link}\">#{link}</a>"
  end
end

def ldap_command(message)
  term = message[6..-1]

  # Connect to LDAP
  conn = LDAP::SSLConn.new( $SETTINGS['LDAP_HOST'], $SETTINGS['LDAP_PORT'].to_i )
  conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
  conn.bind(dn = $SETTINGS['LDAP_BASE_DN'], password = $SETTINGS['LDAP_BASE_PW'] )

  search_terms = "(|(uid=#{term})(mail=#{term})(givenName=#{term})(sn=#{term})(cn=#{term}))"
  results = ""
  result_count = 0;

  conn.search($SETTINGS['LDAP_SEARCH_DN'], LDAP::LDAP_SCOPE_SUBTREE, search_terms) do |entry|
    if result_count > 0
      results += "<br>"
    end

    result_count = result_count + 1

    unless entry.get_values('displayName').to_s[2..-3].nil?
      name = entry.get_values('displayName').to_s[2..-3]
    else
      name = "Not listed"
    end
    unless entry.get_values('uid').to_s[2..-3].nil?
      loginid = entry.get_values('uid').to_s[2..-3]
    else
      loginid = "Not listed"
    end
    unless entry.get_values('mail').to_s[2..-3].nil?
      mail = entry.get_values('mail').to_s[2..-3]
    else
      mail = "Not listed"
    end
    unless entry.get_values('street').to_s[2..-3].nil?
      office = entry.get_values('street').to_s[2..-3]
    else
      office = "Not listed"
    end
    unless entry.get_values('ou').to_s[2..-3].nil?
      department = entry.get_values('ou').to_s[2..-3]
    else
      department = "Not listed"
    end

    affiliations = []
    # A person may have multiple affiliations
    entry.get_values('ucdPersonAffiliation').each do |affiliation_name|
      affiliations << affiliation_name
    end
    if affiliations.length == 0
      affiliations = "Not listed"
    else
      affiliations = affiliations.join(", ")
    end

    results += "<b>Name</b> #{name}<br>"
    results += "<b>Login ID</b> #{loginid}<br>"
    results += "<b>E-Mail</b> <a href=\"mailto:#{mail}\">#{mail}</a><br>"
    results += "<b>Department</b> #{department}<br>"
    results += "<b>Office</b> #{office}<br>"
    results += "<b>Affiliation</b> #{affiliations}<br>"
  end

  conn.unbind

  if result_count > LDAP_MAX_RESULTS
    return "Too many results (#{result_count}). Try narrowing your search."
  elsif result_count == 0
    return "No results found."
  else
    return results
  end
end
