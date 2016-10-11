module SlackBotCommand
  class Help
    TITLE = "Help"
    REGEX = /^!help/
    COMMAND = '!help [command]'
    DESCRIPTION = "Lists all commands available on the channel. !help <title> for more details of a specific command"
    ENABLED_CHANNELS = ['ALL']

    def run(message)
      specificCommand = /(^!help)\s+([^\s]+)/.match(message)
      response = specificCommand ? "" : "Here is a list of available commands in the format `<title>: <command>`:\n"
      # Match the message to the first compatible command
      SlackBotCommand.constants.each do |command|
        # Get a reference of the command class
        commandClassReference = SlackBotCommand.const_get(command)
        commandClassReference::ENABLED_CHANNELS.each do |channel|
          if channel == "ALL" || channel == SlackBotCommand.getSource
            if specificCommand
              # Define a single command
              if commandClassReference::TITLE.downcase == specificCommand[2].downcase
                response += "*" + commandClassReference::TITLE + "*\n"
                response += "`" + commandClassReference::COMMAND + "`\n"
                response += ">" + commandClassReference::DESCRIPTION + "\n"
              end
            else
              # List every command
              response += ">"
              response += "*" + commandClassReference::TITLE + "*: `"
              response += commandClassReference::COMMAND + "`\n"
            end
          end
        end
      end

      response = specificCommand ? "" : response + "\n You can post `!help <title>` for more information on the command. E.g. `!help devboard`"
      return response.empty? ? "No such command" : response
    end # def run
  end # class Help
end
