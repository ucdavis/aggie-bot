require "net/http"

module ChatBotCommand
  class Namstr
    TITLE = "Namstr"        # Title of the command
    REGEX = /^nam/      # REGEX the command needs to look for
    COMMAND = "nam <query>"     # Command to use
    DESCRIPTION = "Searches campus NAMS (via Namstr) IAM for information about a given NAM, building, etc." +
                 "example: `nam 123456`"

    def run(message, channel, private_allowed)
      unless $SETTINGS["NAMSTR_URL"]
        $logger.error "Could not run Namstr comamnd. Check that NAMSTR_URL is defined in settings."
        return "Namstr command is not configured correctly."
      end

      # Grab the query to run for Namstr
      query = message.scan(/(\S+)/)
      return "Namstr query not understood" if query.length < 2
      query.shift # gets rid of 'nam'

      results = fetch_namstr_data(query.join(' '))
      # Returns early if results is an error message
      return results if results.class == String

      response = ""
      results.each do |result|
        response = response + format_response(result)
        response = response + "\n\n"
      end

      return response
    end

    # Formats the data from Namstr API to a prettier format
    def format_response(result)
      # Store all formatted data in this array
      formatted_data = []

      unless result["namNumber"].empty?
        formatted_data.push "*NAM #* #{result["namNumber"]} (#{result["status"]})"
      end
      unless result["vlan"].empty?
        formatted_data.push "*VLAN* #{result["vlan"]}"
      end
      unless result["building"].empty? || result["room"].empty?
        formatted_data.push "*Location* #{result["room"]} #{result["building"]}"
      end
      unless result["subnet"].empty?
        formatted_data.push "*Subnet* #{result["subnet"]}"
      end
      unless result["mask"].empty?
        formatted_data.push "*Subnet Mask* #{result["mask"]}"
      end
      unless result["caanZone"].empty?
        formatted_data.push "*CAAN Zone* #{result["caanZone"]}"
      end
      unless result["billingId"].empty?
        formatted_data.push "*Billing ID* #{result["billingId"]}"
      end
      unless result["department"].empty?
        unit = []
        unit.push(result["college"]) if result["college"]
        unit.push(result["division"]) if result["division"]
        unit.push(result["department"]) if result["department"]

        formatted_data.push "*Unit* #{unit.join(', ')}"
      end
      unless result["techContact"].empty? || result["email"].empty? || result["phone"].empty?
        formatted_data.push "*Contact* #{result["techContact"]} #{result["email"]} #{result["phone"]}"
      end

      return formatted_data.join("\n")
    end

    # Returns an object containing the result from an api call, else a string with the error message
    # @param query - parameters to add in the GET call
    def fetch_namstr_data(query)
      uri = URI.parse($SETTINGS["NAMSTR_URL"] + '/' + URI.escape(query));

      http = Net::HTTP.new(uri.host, uri.port)
      http.set_debug_output($logger)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if response.code == "200"
        data = JSON.parse(response.body)

        return "Namstr response not understood." if data["results"] == nil
        return "Namstr response not understood." unless data["results"].is_a?(Array)

        return data["results"]
      else
        $logger.error "Could not connect to Namstr API due to #{response.code}"
        return "Could not connect to Namstr API due to #{response.code}"
      end
    end

    @@instance = Namstr.new
    def self.get_instance
      return @@instance
    end

    # Avoids any "accidental" call to new outside of the class
    private_class_method :new
  end
end
