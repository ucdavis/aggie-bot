module ChatBotCommand
  class Help
    TITLE = "Help"
    REGEX = /^!help/
    COMMAND = '!help [command]'
    DESCRIPTION = "Lists all commands available on the channel. !help <title> for more details of a specific command"

    def run(message)
      specificCommand = /(^!help)\s+([^\s]+)/.match(message)
      response = specificCommand ? "" : "Here is a list of available commands in the format `<title>: <command>`:\n"
      # Match the message to the first compatible command
      ChatBotCommand.constants.each do |command|
        # Get a reference of the command class
        commandClassReference = ChatBotCommand.const_get(command)

        # If specificCommand is not nil and the command is enabled for the channel
        # then display the command with its Description
        # otherwise, give a list of all available commands for the channel
        if specificCommand && ChatBotCommand.is_enabled_for(ChatBotCommand.getSource, commandClassReference::TITLE)
          # Define a single command
          if commandClassReference::TITLE.downcase == specificCommand[2].downcase
            response += "*" + commandClassReference::TITLE + "*\n"
            response += "`" + commandClassReference::COMMAND + "`\n"
            response += ">" + commandClassReference::DESCRIPTION + "\n"
          end
        elsif ChatBotCommand.is_enabled_for(ChatBotCommand.getSource, commandClassReference::TITLE)
          # List every command
          response += ">"
          response += "*" + commandClassReference::TITLE + "*: `"
          response += commandClassReference::COMMAND + "`\n"
        end
      end # ChatBotCommand.constants loop

      response = specificCommand ? response : response + "\n You can post `!help <title>` for more information on the command. E.g. `!help devboard`"
      return response.empty? ? "No such command" : response
    end # def run
  end # class Help
end
