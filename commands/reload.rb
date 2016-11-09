module ChatBotCommand
  class Reload
    TITLE = "Reload"        # Title of the command
    REGEX = /^!reload/      # REGEX the command needs to look for
    COMMAND = "!reload"     # Command to use
    DESCRIPTION = "Reloads chatbot config files"       # Description of the command

    # Returns a string indicating if chatbot reloaded its $SETTINGS properly or not
    # @param message - message posted
    # @param channel - the channel where the message was posted
    # @param can_view_private - flag if extra data can be outputted
    def run(message, channel, private_allowed)
      # Reload sensitive settings from config/*
      settings_file = $cwd + '/config/settings.yml'
      if File.file?(settings_file)
        $SETTINGS = YAML.load_file(settings_file)

        if $SETTINGS["GLOBAL"] == nil
          $logger.error "DSS ChatBot could not reload because #{settings_file} does not have a GLOBAL section. See config/settings.example.yml."
          return "Settings file found but missing GLOBAL section. Cannot proceed."
          exit
        end

        return "Settings reloaded."
      else
        $logger.error "DSS ChatBot could not reload because #{settings_file} does not exist. See config/settings.example.yml."
        return "DSS ChatBot could not reload because #{settings_file} does not exist."
      end
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
