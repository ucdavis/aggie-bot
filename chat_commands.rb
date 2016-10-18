# Module that wraps around each command
module ChatBotCommand

  # Load all the commands from the commands folder
  # @param cwd - current working directory of the project
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
  # @param channel - Where the message was posted
  # @param command_title - Title of the command
  def ChatBotCommand.is_enabled_for(channel, command_title)
    channel = "GLOBAL" unless $SETTINGS[channel]

    # If the command is not specified on the channel,
    # then check the global settings for the command
    if $SETTINGS[channel][command_title] == nil
      return $SETTINGS["GLOBAL"][command_title]
    else
      return $SETTINGS[channel][command_title]
    end
  end
end
