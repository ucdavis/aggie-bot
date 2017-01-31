module ChatBotCommand
  class ServiceNow
    TITLE = "ServiceNow"
    REGEX = /\b(INC[0-9]+)/i # look for 'INC' followed by numbers, e.g. INC012983
    COMMAND = "Offers links to ServiceNow when incident numbers are mentioned, e.g. INC12345"
    DESCRIPTION = "Offers a link to ServiceNow incidents when they're mentioned"

    # is_number? credit: http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
    def is_number?(string)
      true if Float(string) rescue false
    end

    def run(message, channel, private_allowed)
      unless $SETTINGS["SERVICENOW_URL"]
        $logger.error "Cannot run ServiceNow command: ensure SERVICENOW_URL is in settings."
        return "ServiceNow support not correctly configured."
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
        messages.push "#{$SETTINGS["SERVICENOW_URL"]}" + m[0]
      end

      return messages.join("\n")
    end

    @@instance = ServiceNow.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
