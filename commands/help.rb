module SlackBotCommand
  class Help
    REGEX = /^!help/
    COMMAND = '!help [command]'
    DESCRIPTION = "Lists all commands available on the channel. !help <command> for more details of a specific command"
    ENABLED_CHANNELS = ['ALL']

    def run(message)
      availableCommands = "";
      # Match the message to the first compatible command
      SlackBotCommand.constants.each do |command|
        # Get a reference of the command class
        commandClassReference = SlackBotCommand.const_get(command)
        commandClassReference::ENABLED_CHANNELS.each do |channel|
          if channel == "ALL" || channel == SlackBotCommand.getSource
            availableCommands += "*" + commandClassReference::COMMAND + "*\n"
            availableCommands += ">" + commandClassReference::DESCRIPTION + "\n"
          end
        end
      end

      return availableCommands
    end # def run
  end # class Help
end
