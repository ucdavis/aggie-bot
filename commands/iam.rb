require "net/http"

module ChatBotCommand
  class Iam
    TITLE = "Iam"        # Title of the command
    REGEX = /^!iam/      # REGEX the command needs to look for
    COMMAND = "!iam <options> <query>"     # Command to use
    DESCRIPTION = "Searches campus IAM for information about a given individual."
                + "```options: \n"
                + "\tname    - queries by full display name"
                + "\tfirst   - queries by first name"
                + "\tlast    - queries by last name"
                + "\temail   - queries by email"
                + "\tloginid - queries by kerberos username"
                + "\tiamid   - queries by iamid"
                + "```"
                + "example: `!iam email user@ucdavis.edu`"

    # TODO: Update to show multiple results
    def run(message, channel)
      # Grab the query to run for IAM
      query = message.scan(/(\S+)/)
      query.shift # gets rid of !iam

      iam_id = get_iam_id(query)

      # Returns early if iam_id is an error message
      return iam_id unless iam_id.to_i != 0

      puts "Gathering data"
      response = gather_data(iam_id)
      #
      # return format_data(response)
    end

    # Returns an hash-map with all the necessary data to output
    # @param iam_id - iam_id of user
    def gather_data iam_id
      # Determine affiliation
      api = "api/iam/people/search/"
      affiliations = get_from_api(api, {"iamId" => iam_id})
      affiliations = affiliations[0]

      # Get all common information
      # api/iam/people/search | name, affiliations, id
      # api/iam/people/contactinfo/search | contact info
      # api/iam/people/prikerbacct/search | kerberos
      # api/iam/associations/pps/search? -- check normal students

      # Get data based on affiliations
      if affiliations["isEmployee"]
        # iam/associations/odr/search ?
        puts "An employee"
      end

      if affiliations["isHSEmployee"]
        # api/iam/associations/hs/search
        puts "an HS employee"
      end

      if affiliations["isFaculty"]
        puts "a faculty"
      end

      if affiliations["isStudent"]
        # api/iam/associations/pps/search ? all ?
        # api/iam/associations/sis/search
        puts "a student"
      end

      if affiliations["isStaff"]
        # iam/associations/odr/search ?
        puts "a staff"
      end

      if affiliations["isExternal"]
        puts "an external"
      end
    end

    # Returns the iam id of the query, a string otherwise
    # @param query - Slack message without !iam
    def get_iam_id query
      command = query.shift
      command = command[0].downcase # required since shift returns an array
      query = query.join(" ")       # Convert query to a string
      iam_id = "No result found"

      case command
      when "name"
        # TODO:  May have to refactor the command to do -first -last else we can't determine it
        iam_id = "Currently unavailable."
      when "first"
        api = "api/iam/people/search";
        query = {"dFirstName" => query}
      when "last"
        api = "api/iam/people/search";
        query = {"dLastName" => query}
      when "iamid"
        return query
      when "loginid"
        # TODO: Could also be non-kerberos? HSAD
        # api/iam/people/prihsadacct/search
        api = "api/iam/people/prikerbacct/search"
        query = {"userId" => query}
      when "email"
        query = decode_slack(query)
        api = "api/iam/people/contactinfo/search"
        query = {"email" => query}
      else
        return command + " is not a valid option. !help iam for more details"
      end

      result = get_from_api(api, query)

      # get_from_api returns a string message if iamId is not found
      iam_id = result.class == String ? result : result[0]["iamId"] unless result.empty?

      return iam_id
    end

    def format_data data

    end

    # Returns an object containing the result from an api call
    # @param api - specific api extension to append
    # @param query - parameters to add in the GET call
    def get_from_api api, query
      uri = URI.parse($SETTINGS["IAM_HOST"] + "/" + api);
      query["key"] = $SETTINGS["IAM_API_TOKEN"]
      uri.query = URI.encode_www_form(query)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if response.code == "200"
        data = JSON.parse(response.body)
        if data["responseStatus"] == 0
          return data["responseData"]["results"]
        else
          $logger.warn "IAM is down"
          return "IAM is currently down"
        end
      else
        $logger.error "Could not connect to Slack API due to #{response.code}"
        return "Could not connect to Slack API due to #{response.code}"
      end
    end

    # Removes any Slack-specific encoding
    def decode_slack(string)
      if string
        # Strip e-mail encoding (sample: "<mailto:somebody@ucdavis.edu|somebody@ucdavis.edu>")
        mail_match = /mailto:([\S]+)\|/.match(string)
        string = mail_match[1] if mail_match
      end

      return string
    end

    # Essential to make commands a singleton
    @@instance = Iam.new
    def self.get_instance
      return @@instance
    end

    # Avoids any "accidental" call to new outside of the class
    private_class_method :new
  end
end
