module ChatBotCommand
  class DevPlaygroundCommand
    TITLE = "DevPlaygroundCommand"
    REGEX = /\b(NKB[0-9]+)/i # look for 'KB' followed by numbers, e.g. KB012983
    COMMAND = "Offers links to ServiceNow when knowledge base numbers are mentioned, e.g. KB12345"
    DESCRIPTION = "Offers a link to the ServiceNow knowledge base when KB articles are mentioned"

    def run(message, channel, private_allowed)
      unless $SETTINGS["SERVICENOW_KB_URL"]
        $logger.error "Cannot run DevPlaygroundCommand command: ensure SERVICENOW_KB_URL is in settings."
        return "DevPlaygroundCommand support not correctly configured."
      end

      messages = []
      matches = nil

      case message
      # look for characters at the beginning of the line or following a space
      # followed by / followed by numbers, e.g. dw/123
      when /(KB[0-9]+)/i then
        matches = message.scan(/(KB[0-9]+)/i)
      end

      return [] unless matches

      matches.each do |m|
        kbNumber = m[0].split("KB")[1].rjust(7, "0")
        messages.push "#{$SETTINGS["SERVICENOW_KB_URL"]}" + "KB" + kbNumber
      end

      return messages.join("\n")
    end

    @@instance = DevPlaygroundCommand.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
