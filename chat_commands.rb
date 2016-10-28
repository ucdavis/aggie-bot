require "net/http"

# Module that wraps around each command
module ChatBotCommand

  # Load all the commands from the commands folder
  # @param cwd - current working directory of the project
  def ChatBotCommand.initialize(cwd)
    # Load all commands
    Dir[cwd + "/commands/*.rb"].each {|file| require file }
  end

  # Runs the proper command based on the message
  # Returns a string to output if a command is found, else nil
  # @param message - The message sent on slackbot e.g. !help
  # @param channel - The channel where the message was sent e.g. dss-it-appdev
  def ChatBotCommand.run(message, channel)
    # Match the message to the first compatible command
    ChatBotCommand.constants.each do |command|
      # Get a reference of the command class
      command_class_reference = ChatBotCommand.const_get(command)

      # Check if the assigned REGEX matches the message passed
      if command_class_reference::REGEX.match(message)
        # Run the command and return its response message unless it is not enabled
        if is_enabled_for(channel, command_class_reference::TITLE)
          response = command_class_reference.get_instance.run(message, channel)
          if response.is_a? (String)
            return response
          else
            $logger.error(command_class_reference::TITLE + " does not return a String")
            return nil
          end
        end
      end
    end
  end # def ChatBotCommand.run

  # Check if a command is enabled for the channel
  # @param channel - ID of where the message was posted
  # @param command_title - Title of the command
  def ChatBotCommand.is_enabled_for(channel, command_title)
    # Create a hash :channel_id => channel_name of both private and public channels
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
    response = slack_api("channels.list", {})
    unless response == nil
      response["channels"].each do |channel|
        channels[channel["id"]] = channel["name"]
      end
    end

    response = slack_api("groups.list", {})
    unless response == nil
      response["groups"].each do |channel|
        channels[channel["id"]] = channel["name"]
      end
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


end
