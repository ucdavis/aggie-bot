module SlackBotCommand
  class Help
    REGEX = /^!help/
    COMMAND = '!help [command]'
    DESCRIPTION = "Lists all commands available on the channel. !help <command> for more details of a specific command"
    ENABLED_CHANNELS = ['ALL']

    def run(message)
      specificCommand = /(^!help)\s+([^\s]+)/.match(message)
      response = specificCommand ? "" : "Here is a list of available commands:\n>>>"
      # Match the message to the first compatible command
      SlackBotCommand.constants.each do |command|
        # Get a reference of the command class
        commandClassReference = SlackBotCommand.const_get(command)
        commandClassReference::ENABLED_CHANNELS.each do |channel|
          if channel == "ALL" || channel == SlackBotCommand.getSource
            if specificCommand
              # Define a single command
              if commandClassReference::REGEX.match(specificCommand[2])
                response += "*" + commandClassReference::COMMAND + "*\n"
                response += ">" + commandClassReference::DESCRIPTION + "\n"
              end
            else
              # List every command
              response += commandClassReference::COMMAND + "\n"
            end
          end
        end
      end

      return response
    end # def run
  end # class Help
end
