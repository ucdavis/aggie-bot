module SlackBotCommand
  class Host
    REGEX = "/^host/"
    COMMAND = "host TODO"
    DESCRIPTION = "TODO"

    # Returns true if 'string' is an IP address or hostname, e.g. 'www.ucdavis.edu' or '192.168.1.1'
    def valid_ip_or_hostname(string)
      if string
        # Simple IP address reg ex (from https://www.safaribooksonline.com/library/view/regular-expressions-cookbook/9780596802837/ch07s16.html)
        ip_match = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.match(string)
        return true if ip_match

        # Hostname reg ex
        host_match = /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$/.match(string)
        return true if host_match
      end

      return false
    end

    def isEnabledFor(channel)
      enabledChannels = ['GLOBAL', 'D2HPTUNSW']
      enabledChannels.each do |enabledChannel|
        if channel == enabledChannel
          return true
        end
      end

      return false
    end

    # Runs the UNIX 'host' command with the given query.
    # Expects 'message' to begin with 'host ' + the given query, e.g. 'host www.ucdavis.edu'
    def run(message)
      query = message[5..-1] # Strip away the beginning "host "

      unless valid_ip_or_hostname(query)
        @logger.warn "Invalid IP or hostname for 'host' command: '#{query}'"
        return "Query does not appear to be an IP address nor hostname."
      end

      # Call the script, piping the JSON
      ret = IO.popen("host #{query}", 'r+', :err => [:child, :out]) do |pipe|
        pipe.close_write
        pipe.gets(nil)
      end

      if $?.exitstatus != 0
        # Error
        @logger.warn "'host' command did not exit cleanly, status: #{$?.exitstatus}. Output:"
        @logger.warn ret
        @logger.warn "End of output."
        return "Error running 'host' command. Exit status: #{$?.exitstatus}"
      else
        # Success
        if ret and ret.length > 0
          return "```" + ret + "```"
        else
          @logger.warn "'host' exited cleanly but produced no output."
          return "'host' exited cleanly but produced no output."
        end
      end
    end
  end
end
