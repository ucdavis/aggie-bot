# Grab cwd because daemon changes it
$cwd = Dir.getwd

# Module that wraps around each command
module ChatBotCommand
  # ChatBotCommand Variables
  @@messageSource

  # Getter to access from new commands
  def ChatBotCommand.getSource
    return @@messageSource
  end

  # Load all commands
  Dir[$cwd + "/commands/*.rb"].each {|file| require file }

  # Runs the proper command based on the message
  # It should return a string to output if a command is found
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
        if isEnabledFor(messageSource, commandClassReference::ENABLED_CHANNELS)
          return commandClassReference.new.run(message)
        end
      end
    end
  end # def ChatBotCommand.run

  def ChatBotCommand.isEnabledFor(channel, enabledChannels)
    enabledChannels.each do |enabledChannel|
      if (enabledChannel == "ALL") || (channel == enabledChannel)
        return true
      end
    end

    return false
  end # def isEnabledFor
end
