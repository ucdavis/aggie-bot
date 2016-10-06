# Grab cwd because daemon changes it
$cwd = Dir.getwd

# Module that wraps around each command
module SlackBotCommand
  # Load all commands
  Dir[$cwd + "/commands/*.rb"].each {|file| require file }

  # Runs the proper command based on the message
  # It should return a string to output if a command is found
  def SlackBotCommand.run(message, messageSource)
    # Match the message to the first compatible command
    SlackBotCommand.constants.each do |command|
      # Get a reference of the command class
      commandClassReference = SlackBotCommand.const_get(command)

      # Check if the assigned REGEX matches the message passed
      if (commandClassReference::REGEX.match(message))
        # Run the command and
        # return its response message
        # unless it is not enabled
        commandClass = commandClassReference.new
        if commandClass.isEnabledFor(messageSource)
          return commandClass.run(message)
        end
      end
    end
  end # def SlackBotCommand.run
end
