module ChatBotCommand
  class ServiceNowChangeRequests
    TITLE = "ServiceNowChangeRequests"
    REGEX = /\b(CHG[0-9]+)/i # look for 'CHG' followed by numbers, e.g. CHG012983
    COMMAND = "Offers links to ServiceNow when change requests are mentioned, e.g. CHG12345"
    DESCRIPTION = "Offers a link to ServiceNow change requests when they're mentioned"

    def run(message, channel, private_allowed)
      unless $SETTINGS["SERVICENOW_CR_URL"]
        $logger.error "Cannot run ServiceNowChangeRequests command: ensure SERVICENOW_CR_URL is in settings."
        return "ServiceNowChangeRequests support not correctly configured."
      end

      messages = []
      matches = nil

      case message
      # look for characters at the beginning of the line or following a space
      # followed by / followed by numbers, e.g. dw/123
    when /(CHG[0-9]+)/i then
        matches = message.scan(/(CHG[0-9]+)/i)
      end

      return [] unless matches

      matches.each do |m|
        messages.push "#{$SETTINGS["SERVICENOW_CR_URL"]}" + m[0]
      end

      return messages.join("\n")
    end

    @@instance = ServiceNowChangeRequests.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
