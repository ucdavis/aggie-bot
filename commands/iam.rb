require "net/http"

module ChatBotCommand
  class Iam
    TITLE = "Iam"        # Title of the command
    REGEX = /^!iam/      # REGEX the command needs to look for
    COMMAND = "!iam <options> <query>"     # Command to use
    DESCRIPTION = "Searches campus IAM for information about a given individual." +
                 " \n*<options>* \n" +
                 ">\tfirst   - queries by first name\n" +
                 ">\tlast    - queries by last name\n" +
                 ">\temail   - queries by email\n" +
                 ">\tloginid - queries by kerberos username\n" +
                 ">\tiamid   - queries by iamid\n" +
                 "example: `!iam email user@ucdavis.edu`"


    def run(message, channel)
      # Grab the query to run for IAM
      query = message.scan(/(\S+)/)
      query.shift # gets rid of !iam

      iam_id = get_iam_id(query)
      # Returns early if iam_id is an error message
      return iam_id unless iam_id.class != String

      if iam_id.size > 10
        return "Too many individuals to show"
      end

      response = ""
      iam_id.each do |id|
        data = gather_data(id)
        response = response + format_data(data)
        response = response + "\n\n"
      end

      return response
    end

    # Returns a hash-map with all the necessary data to output else an empty hash
    # @param iam_id - iam_id of user
    def gather_data iam_id
      result = {}
      # Each we use ___[0] because get_from_api returns an array
      # We know we only need [0] because we are querying by iamId

      # Get ids, names and affiliations
      basic_info = get_from_api("api/iam/people/search", {"iamId" => iam_id})
      result["basic_info"] = basic_info.empty? ? [] : basic_info

      # Get email, postaladdress, phone numbers
      contact_info = get_from_api("api/iam/people/contactinfo/search", {"iamId" => iam_id})
      result["contact_info"] = contact_info.empty? ? [] : contact_info

      # Get kerberos loginid
      kerberos_info = get_from_api("api/iam/people/prikerbacct/search", {"iamId" => iam_id})
      result["kerberos_info"] = kerberos_info.empty? ? [] : kerberos_info

      # Get PPS department, title, and position type
      pps_info = get_from_api("api/iam/associations/pps/search", {"iamId" => iam_id})
      result["pps_info"] = pps_info.empty? ? [] : pps_info

      # Get ODR department and title
      odr_info = get_from_api("api/iam/associations/odr/search", {"iamId" => iam_id})
      result["odr_info"] = odr_info.empty? ? [] : odr_info

      # Get HS employee information
      hs_info = get_from_api("api/iam/associations/hs/search", {"iamId" => iam_id})
      result["hs_info"] = hs_info.empty? ? [] : hs_info

      # Get student information
      student_info = get_from_api("api/iam/associations/sis/search", {"iamId" => iam_id})
      result["student_info"] = student_info.empty? ? [] : student_info

      return result
    end

    # Returns an array of iam_ids, a string if no iam_id is found
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
        return [query]
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
      unless result.empty?
        iam_id = []
        result.each do |data|
          iam_id.push data["iamId"]
        end
      end

      return iam_id
    end

    # Formats the data from IAM API to a prettier format
    # @param data - the hash obtained from gather_data
    def format_data data
      # Store all formatted data in this array
      formatted_data = []

      # Format name with flags
      # Name Mark Diez (student, employee, staff)
      if !data["basic_info"].empty?
        data["basic_info"].each do |info|
          name = "*Name* " + info["dFullName"]

          flags = []
          if info["isEmployee"]
            flags.push "employee"
          end
          if info["isHSEmployee"]
            flags.push "hs employee"
          end
          if info["isFaculty"]
            flags.push "faculty"
          end
          if info["isStudent"]
            flags.push "student"
          end
          if info["isStaff"]
            flags.push "staff"
          end
          if info["isExternal"]
            flags.push "external"
          end
          flags = " _(" + flags.join(", ") + ")_"
          name += flags

          formatted_data.push name
        end
      end

      # Format Kerberos information
      # Login ID msdiez, anotherid, ...
      if !data["kerberos_info"].empty?
          ids = []
        data["kerberos_info"].each do |info|
          id = info["userId"] == nil ? "Not Listed" : info["userId"]
          ids.push id
        end

        formatted_data.push "*Login ID* " + ids.join(", ")
      else
        login_id = "*Login ID* Not Listed"
        formatted_data.push login_id
      end


      # Format contact information
      # E-mail my@email.com, my@otheremail.com
      # Office kerr 186, social science 133, ...
      if !data["contact_info"].empty?
        email = []
        office = []
        data["contact_info"].each do |info|
          email.push info["email"] unless info["email"] == nil
          office.push info["addrStreet"] unless info["addrStreet"] == nil
        end
        formatted_data.push "*E-mail* " + email.join(", ")
        formatted_data.push "*Office* " + office.join(", ")
      else
        formatted_data.push "*E-mail* Not Listed"
        formatted_data.push "*Office* Not Listed"
      end

      # Format HS information
      # HS Affiliation Nurse Clinical II (D-10 Pediatric ICU/PCICU)
      if !data["hs_info"].empty?
        data["hs_info"].each do |info|
          hs = "*HS Affiliation* "
          hs += info["titleDisplayName"] unless info["titleDisplayName"] == nil
          hs += " (" + info["costCenterDisplayName"] + ")" unless info["costCenterDisplayName"] == nil

          formatted_data.push hs
        end
      end

      # Format ODR information
      # ODR Affiliation DSSIT: STD4 (Casual)
      if !data["odr_info"].empty?
        data["odr_info"].each do |info|
          odr = "*ODR Affiliation* "
          odr += info["deptDisplayName"] + ": " unless info["deptDisplayName"] == nil
          odr += info["titleDisplayName"] unless info["titleDisplayName"] == nil

          formatted_data.push odr
        end
      end

      # Format PPS information
      # PPS Affiliation DSSIT: STD4
      if !data["pps_info"].empty?
        data["pps_info"].each do |info|
          pps = "*PPS Affiliation* "
          pps += info["deptDisplayName"] + ": " unless info["deptDisplayName"] == nil
          pps += info["titleDisplayName"]unless info["titleDisplayName"] == nil
          pps += " (" + info["positionType"] + ")" unless info["positionType"] == nil

          formatted_data.push pps
        end
      end

      # Format student information
      # Student Affiliation Computer Science (Undergraduate, Junior)
      if !data["student_info"].empty?
        data["student_info"].each do |info|
          student = "*Student Affiliation* "
          student += info["majorName"] + " ("
          student += info["levelName"].scan(/\S+/)[0] # Only grab the first word
          student +=  ", " + info["className"] + ")"

          formatted_data.push student
        end
      end

      return formatted_data.join("\n")
    end

    # Returns an object containing the result from an api call, else an error message
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
