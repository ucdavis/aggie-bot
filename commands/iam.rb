require "net/http"

module ChatBotCommand
  class Iam
    TITLE = "Iam"        # Title of the command
    REGEX = /^!iam/      # REGEX the command needs to look for
    COMMAND = "!iam <options> <query>"     # Command to use
    DESCRIPTION = "Searches campus IAM for information about a given individual."
                + "```options: \n"
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

      response = gather_data(iam_id)
      return format_data(response)
    end

    # Returns an hash-map with all the necessary data to output
    # @param iam_id - iam_id of user
    def gather_data iam_id
      result = {}

      # Get ids, names and affiliations
      basic_info = get_from_api("api/iam/people/search", {"iamId" => iam_id})
      result["basic_info"] = basic_info.empty? ? [] : basic_info[0]

      # Get email, postaladdress, phone numbers
      contact_info = get_from_api("api/iam/people/contactinfo/search", {"iamId" => iam_id})
      result["contact_info"] = contact_info.empty? ? [] : contact_info[0]

      # Get kerberos loginid
      kerberos_info = get_from_api("api/iam/people/prikerbacct/search", {"iamId" => iam_id})
      result["kerberos_info"] = kerberos_info.empty? ? [] : kerberos_info[0]

      # Get PPS department, title, and position type
      pps_info = get_from_api("api/iam/associations/pps/search", {"iamId" => iam_id})
      result["pps_info"] = pps_info.empty? ? [] : pps_info[0]

      # Get ODR department and title
      odr_info = get_from_api("api/iam/associations/odr/search", {"iamId" => iam_id})
      result["odr_info"] = odr_info.empty? ? [] : odr_info[0]

      # Get HS employee information
      hs_info = get_from_api("api/iam/associations/hs/search", {"iamId" => iam_id})
      result["hs_info"] = hs_info.empty? ? [] : hs_info[0]

      # Get student information
      student_info = get_from_api("api/iam/associations/sis/search", {"iamId" => iam_id})
      result["student_info"] = student_info.empty? ? [] : student_info[0]

      return result
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
      response = "*Name* " + data["basic_info"]["dFullName"] + "\n"
               + "*Login ID* " + data["kerberos_info"]["userId"] + "\n"
               + "*E-Mail* " + data["contact_info"]["email"] + "\n"

      response += "*Department* "
      if !data["odr_info"].empty?
        response += data["odr_info"]["deptDisplayName"]
      elsif !data["pps_info"].empty?
        response += data["pps_info"]["deptDisplayName"] + " (" + data["pps_info"]["deptCode"] + ")"
      else
        response += "Not Listed"
      end
      response += "\n"

      response += "*Title* "
      if !data["odr_info"].empty?
        response += data["odr_info"]["titleDisplayName"]
      elsif !data["pps_info"].empty?
        response += data["pps_info"]["titleDisplayName"]
      else
        response += "Not Listed"
      end
      response += "\n"

      response += "*Office* " + data["contact_info"]["addrStreet"] + "\n"


      response += "*Affiliations* "
      response = data["basic_info"]["isStaff"] ? response + "staff: " + data["pps_info"]["positionType"] : response

      response = data["basic_info"]["isStudent"] ? response + " student: " + data["student_info"]["levelName"] + ", " + data["student_info"]["majorName"] : response

      return response
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
