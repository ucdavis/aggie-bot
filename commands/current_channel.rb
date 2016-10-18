module ChatBotCommand
  class CurrentChannel
    TITLE = "CurrentChannel"        # Title of the command
    REGEX = /^!channel/      # REGEX the command needs to look for
    COMMAND = "!channel"     # Command to use
    DESCRIPTION = "Output the channel code for the current channel"       # Description of the command

    def run(message, channel)
      return channel
    end

    @@instance = CurrentChannel.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
