module ChatBotCommand
  class ServiceNowTickets
    TITLE = "ServiceNowTickets"
    REGEX = /\b(INC[0-9]+)/i # look for 'INC' followed by numbers, e.g. INC012983
    COMMAND = "Offers links to ServiceNow when incident numbers are mentioned, e.g. INC12345"
    DESCRIPTION = "Offers a link to ServiceNow incidents when they're mentioned"

    def run(message, channel, private_allowed)
      unless $SETTINGS["SERVICENOW_TICKETS_URL"]
        $logger.error "Cannot run ServiceNowTickets command: ensure SERVICENOW_TICKETS_URL is in settings."
        return "ServiceNowTickets support not correctly configured."
      end

      messages = []
      matches = nil

      case message
      # look for characters at the beginning of the line or following a space
      # followed by / followed by numbers, e.g. dw/123
      when /(INC[0-9]+)/i then
        matches = message.scan(/(INC[0-9]+)/i)
      end

      return [] unless matches

      matches.each do |m|
        messages.push "#{$SETTINGS["SERVICENOW_TICKETS_URL"]}" + m[0]
      end

      return messages.join("\n")
    end

    @@instance = ServiceNowTickets.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
