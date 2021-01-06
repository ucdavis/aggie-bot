require 'net/http'

# Module that wraps around each command
module ChatBotCommand

  # Load all the commands from the commands folder
  # @param dir - current working directory of the project
  def ChatBotCommand.initialize(dir)
    # Load all commands
    Dir[dir + '/commands/*.rb'].each do |file|
      begin
        $logger.debug "Loading command #{file} ..."
        require file
      rescue LoadError
        $logger.error "Cannot load command from #{file}, a LoadError occurred."
      end
    end

    $logger.debug "Commands available: #{ChatBotCommand.constants}"
  end

  # Runs the proper command based on the message
  #
  # Returns a string to output if a command is found, else nil
  #
  # @param message - The message sent on slackbot e.g. !help
  # @param channel - The channel where the message was sent e.g. dss-it-appdev
  # @param user - User who sent the message
  # @param is_dm - flag if the event was a direct message
  def ChatBotCommand.dispatch(message, channel, user, is_dm)
    $logger.debug 'Dispatch received:'
    $logger.debug "\tMessage : #{message}"
    $logger.debug "\tChannel : #{channel}"
    $logger.debug "\tUser    : #{user}"
    $logger.debug "\tPrivate : #{is_dm}"

    # Match the message to the first compatible command
    ChatBotCommand.constants.each do |command|
      # Get a reference of the command class
      command_class_reference = ChatBotCommand.const_get(command)
      command_enabled_on_channel = is_enabled_for(channel, command_class_reference::TITLE)
      command_allowed_private = is_allowed_private(command_class_reference::TITLE, user)

      # Run the command and return its response message if it is enabled
      if command_enabled_on_channel || command_allowed_private
        # Check if the assigned REGEX matches the message passed
        regex_match = false
        Array(command_class_reference::REGEX).each do |regex|
          unless regex.match(message) == nil
            regex_match = true
            break
          end
        end

        # If regex matches, run the command
        if regex_match
          $logger.debug "Sending message to #{command_class_reference} as it matches the regex."
          allow_private = is_dm && command_allowed_private
          response = command_class_reference.get_instance.run(message, channel, allow_private)
          if response.is_a? String
            log_user user, $customer_log
            return response
          else
            $logger.error(command_class_reference::TITLE + " did not return a String")
            return nil
          end
        else
          $logger.debug "Not sending message to #{command_class_reference} as it fails to match the regex."
        end
      else
        unless command_enabled_on_channel
          $logger.debug "Not sending message to #{command_class_reference} as it is not enabled on channel and/or for private use."
        end
        unless command_allowed_private
          $logger.debug "Not sending message to #{command_class_reference} as it is not allowing private messages."
        end
      end
    end

    return nil
  end

  # Returns true if a command is enabled for the channel, otherwise false / nil
  # @param channel - ID of where the message was posted
  # @param command_title - Title of the command
  # @param username - username of slack user
  def ChatBotCommand.is_enabled_for(channel, command_title)
    # Create a hash :channel_id => channel_name of both private and public channels
    # get_channel_list is called once
    @channel_names ||= get_channel_list

    # Convert channel from channel ID to channel name
    channel = @channel_names[channel]
    channel = "GLOBAL" unless $SETTINGS[channel]

    # If the command is not specified on the channel,
    # then check the global settings for the command
    if $SETTINGS[channel][command_title] == nil
      return $SETTINGS["GLOBAL"][command_title]
    else
      return $SETTINGS[channel][command_title]
    end
  end

  # Returns :id => name hash of both public and private channel names else nil
  def ChatBotCommand.get_channel_list
    channels = {}
    args = {
      cursor: "",
      limit: 1000,
      types: "public_channel,private_channel,mpim"
    }

    loop do
      response = slack_api("conversations.list", args)

      unless response == nil
        response["channels"].each do |channel|
          channels[channel["id"]] = channel["name"]
        end
      end

      next_cursor = response["response_metadata"]["next_cursor"]
      args[:cursor] = next_cursor
      break if next_cursor.empty?
    end

    return channels.empty? ? nil : channels
  end

  # Returns a parsed JSON of the Net::HTTPResponse object of the API call else nil
  # @param method - a string name of the method to use
  # @param args - a hash of additional paramaters for the method
  def ChatBotCommand.slack_api(method, args)
    api = "https://slack.com/api/" + method
    uri = URI.parse(api)

    args["token"] = $SETTINGS["SLACK_API_TOKEN"]
    uri.query = URI.encode_www_form(args)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code == "200"
      return JSON.parse(response.body)
    else
      $logger.error "Could not connect to Slack API due to #{response.code}"
      return nil
    end
  end

  # Reloads the channels
  def ChatBotCommand.reload_channels!
    # Update channel list
    @channel_names = get_channel_list
  end

  # Outputs the username and email of customer to the log
  # @param user - SlackRubyClient::User object of customer
  # @param customer_log - Logger to output
  def ChatBotCommand.log_user(user, customer_log)
    if defined? user
      customer_log.info user.name + " " + user.profile.email
    end
  end

  # Removes any Slack-specific encoding
  def ChatBotCommand.decode_slack(string)
    if string
      # Strip e-mail encoding (sample: "<mailto:somebody@ucdavis.edu|somebody@ucdavis.edu>")
      mail_match = /mailto:([\S]+)\|/.match(string)
      string = mail_match[1] if mail_match
    end

    return string
  end

  # Returns true if the user is eligible to view private data, false otherwise
  # @param command - Title of command
  # @param user    - Slack user object, may be nil
  def ChatBotCommand.is_allowed_private(command, user)
    # Return false if the command does not have a private list of users
    # PRIVATE is optional so the chatbot does not need to exit if it does not exist
    return false if $SETTINGS['PRIVATE'] == nil || $SETTINGS['PRIVATE'][command] == nil
    return false unless defined? user

    command_value = $SETTINGS['PRIVATE'][command]

    if command_value.is_a? TrueClass
      return true
    elsif command_value.is_a? Array
      return !$SETTINGS["PRIVATE"][command].find_index(user.name).nil?
    else
      # settings.yml should only use 'true' or an array
      return false
    end
  end

end
