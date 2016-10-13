# Module that wraps around each command
module ChatBotCommand
  def ChatBotCommand.initializeCommands(cwd)
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
      commandClassReference = ChatBotCommand.const_get(command)

      # Check if the assigned REGEX matches the message passed
      if commandClassReference::REGEX.match(message)
        # Run the command and
        # return its response message
        # unless it is not enabled
        if is_enabled_for(channel, commandClassReference::TITLE)
          response = commandClassReference.new.run(message, channel)
          if response.is_a? (String)
            return response
          end
        end
      end
    end
  end # def ChatBotCommand.run

  # Check if a command is enabled for the channel
  # @param channel - Where the message was posted
  # @param commandTitle - Title of the command
  def ChatBotCommand.is_enabled_for(channel, commandTitle)
    channel = "GLOBAL" unless $SETTINGS[channel]

    # If the command is not specified on the channel,
    # then check the global settings for the command
    if $SETTINGS[channel][commandTitle] == nil
      return $SETTINGS["GLOBAL"][commandTitle]
    else
      return $SETTINGS[channel][commandTitle]
    end
  end
end
