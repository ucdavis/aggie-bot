module ChatBotCommand
  class ServiceNowStdChangeRequests
    TITLE = "ServiceNowStdChangeRequests"
    REGEX = /\b(STDCHG[0-9]+)/i # look for 'STDCHG' followed by numbers, e.g. STDCHG012983
    COMMAND = "Offers links to ServiceNow when standard change requests are mentioned, e.g. STDCHG12345"
    DESCRIPTION = "Offers a link to ServiceNow standard change requests when they're mentioned"

    def run(message, channel, private_allowed)
      unless $SETTINGS["SERVICENOW_SCR_URL"]
        $logger.error "Cannot run ServiceNowStdChangeRequests command: ensure SERVICENOW_SCR_URL is in settings."
        return "ServiceNowStdChangeRequests support not correctly configured."
      end

      messages = []
      matches = nil

      case message
      # look for characters at the beginning of the line or following a space
      # followed by / followed by numbers, e.g. dw/123
    when /(STDCHG[0-9]+)/i then
        matches = message.scan(/(STDCHG[0-9]+)/i)
      end

      return [] unless matches

      matches.each do |m|
        messages.push "#{$SETTINGS["SERVICENOW_SCR_URL"]}" + m[0]
      end

      return messages.join("\n")
    end

    @@instance = ServiceNowStdChangeRequests.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
