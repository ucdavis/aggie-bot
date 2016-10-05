# Grab cwd because daemon changes it
$cwd = Dir.getwd

# Module that wraps around each command
module SlackBotCommand
  # Load all commands
  Dir[$cwd + "/commands/*.rb"].each {|file| require file }

  # Runs the proper command based on the message
  def SlackBotCommand.run(message)
    SlackBotCommand.constants.each |command| do
      # Get a reference of the command class
      commandClassReference = SlackBotCommand.const_get(command)

      # Check if the assigned REGEX matches the message passed
      if (commandClassReference::REGEX.match(message))
        # Run the command
        commandClassReference.new.run(message)
      end
    end
  end
end
