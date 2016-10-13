# Module that wraps around each command
module ChatBotCommand
  # ChatBotCommand Variables
  @@messageSource

  # Getter to access from new commands
  def ChatBotCommand.getSource
    return @@messageSource
  end

  def ChatBotCommand.initializeCommands(cwd)
    # Load all commands
    Dir[cwd + "/commands/*.rb"].each {|file| require file }
  end

  # Runs the proper command based on the message
  # It should return a string to output if a command is found
  # @param message - The message sent on slackbot e.g. !help
  # @param messageSource - The channel where the message was sent e.g. dss-it-appdev
  def ChatBotCommand.run(message, messageSource)
    # Set message source
    @@messageSource = messageSource

    # Match the message to the first compatible command
    ChatBotCommand.constants.each do |command|
      # Get a reference of the command class
      commandClassReference = ChatBotCommand.const_get(command)

      # Check if the assigned REGEX matches the message passed
      if (commandClassReference::REGEX.match(message))
        # Run the command and
        # return its response message
        # unless it is not enabled
        if is_enabled_for(messageSource, commandClassReference::TITLE)
          return commandClassReference.new.run(message)
        end
      end
    end
  end # def ChatBotCommand.run

  # Check if a command is enabled for the channel
  # @param channel - Where the message was posted
  # @param commandTitle - Title of the command
  def ChatBotCommand.is_enabled_for(channel, commandTitle)
    if $SETTINGS[channel] == nil
      channel = "GLOBAL"
    end

    # If the command is not specified on the channel,
    # then check the global settings for the command
    if $SETTINGS[channel][commandTitle] == nil
      return $SETTINGS["GLOBAL"][commandTitle]
    else
      return $SETTINGS[channel][commandTitle]
    end
  end
end
