module ChatBotCommand
  class Reload
    TITLE = "Reload"        # Title of the command
    REGEX = /^!reload/      # REGEX the command needs to look for
    COMMAND = "!reload"     # Command to use
    DESCRIPTION = "Reloads ChatBot config files"       # Description of the command

    # Returns a string indicating if chatbot reloaded its $SETTINGS properly or not
    # @param message - message posted
    # @param channel - the channel where the message was posted
    # @param private_allowed - flag if extra data can be outputted
    def run(message, channel, private_allowed)
      if private_allowed
        $SETTINGS = load_settings($settings_file)
        return $SETTINGS == nil ? "Unable to reload settings" : "Settings reloaded"
      end
      return ""
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
