module ChatBotCommand
  class Help
    TITLE = "Help"
    REGEX = /^!help/
    COMMAND = '!help [command]'
    DESCRIPTION = "Lists all commands available on the channel. !help <title> for more details of a specific command"

    def run(message, channel)
      specific_command = message.scan(/(\S+)/)

      # Remove !help from the array
      specific_command.shift
      response = !specific_command.empty? ? "" : "Here is a list of available commands in the format `<title>: <command>`:\n"
      # Match the message to the first compatible command
      ChatBotCommand.constants.each do |command|
        # Get a reference of the command class
        command_class_reference = ChatBotCommand.const_get(command)

        # If specific_command is not nil and the command is enabled for the channel
        # then display the command with its Description
        # otherwise, give a list of all available commands for the channel
        if !specific_command.empty? && ChatBotCommand.is_enabled_for(channel, command_class_reference::TITLE)
          # Define a single command
          if command_class_reference::TITLE.downcase == specific_command.join(" ").downcase
            response += "*" + command_class_reference::TITLE + "*\n"
            response += "`" + command_class_reference::COMMAND + "`\n"
            response += ">" + command_class_reference::DESCRIPTION + "\n"
          end
        elsif ChatBotCommand.is_enabled_for(channel, command_class_reference::TITLE)
          # List every command
          response += ">"
          response += "*" + command_class_reference::TITLE + "*: `"
          response += command_class_reference::COMMAND + "`\n"
        end
      end # ChatBotCommand.constants loop

      response = specific_command ? response : response + "\n You can post `!help <title>` for more information on the command. E.g. `!help devboard`"
      return response.empty? ? "No such command" : response
    end # def run

    def self.get_instance
      @@instance ||= Help.new
    end

    private_class_method :new
  end # class Help
end
