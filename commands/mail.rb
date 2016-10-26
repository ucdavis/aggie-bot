require 'mechanize'

module ChatBotCommand
  class Mail
    TITLE = "Mail ID"
    REGEX = /^!mailid\s+\S+\s*$/
    COMMAND = "!mailid <Login ID>"
    DESCRIPTION = "Shows the mail forwarding information of a user e.g. `!mailid cmthielen`"

    # Run MUST return a string
    def run(message, channel)
      # Get information
      # Format information
      return "TODO"
    end

    # Essential to make commands a singleton
    @@instance = Mail.new
    def self.get_instance
      return @@instance
    end

    # Avoids any "accidental" call to new outside of the class
    private_class_method :new
  end
end
