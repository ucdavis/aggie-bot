module ChatBotCommand
  class Reload
    TITLE = "Reload"        # Title of the command
    REGEX = /^!reload/      # REGEX the command needs to look for
    COMMAND = "!reload"     # Command to use
    DESCRIPTION = "Update chatbot's configuration"       # Description of the command

    # Run MUST return a string
    def run(message, channel)
      return ChatBotCommand.reload
    end

    # Essential to make commands a singleton
    @@instance = Reload.new
    def self.get_instance
      return @@instance
    end

    # Avoids any "accidental" call to new outside of the class
    private_class_method :new
  end
end
