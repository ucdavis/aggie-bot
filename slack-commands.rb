# Grab cwd because daemon changes it
$cwd = Dir.getwd

# Module that wraps around each command
module SlackBotCommand
  # Load all commands
  Dir[$cwd + "/commands/*.rb"].each {|file| require file }

  # Runs the proper command based on the message
  def SlackBotCommand.run(message)
    # Get an instance for each command we have
    # for each command,
      # if the message matches the regex
        # then run the command
      # else
        # move on
  end
end
