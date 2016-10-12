require 'json'
require 'net/http'
require 'net/https'

module ChatBotCommand
  class Devboard
    TITLE = "Devboard"
    REGEX = /^!assignments/
    COMMAND = "!assignments"
    DESCRIPTION = "Outputs the tasks assigned to developers from Devboard"
    ENABLED_CHANNELS = ['ALL']

    # Get data from Devboard
    def run(message)
      uri =  URI.parse($SETTINGS["DEVBOARD_URL"] + "/overview.json");

      # Connect to DevBoard
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == "https"
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth $SETTINGS["DEVBOARD_API_USER"], $SETTINGS["DEVBOARD_API_SECRET"]

      response = http.request(request)

      # Retrieve assignments for each developer from DevBoard
      message = ""
      if response.code == "200"
        result = JSON.parse(response.body)
        if result
          open_assignments = result["open_assignments"]

          if open_assignments
            open_assignments.each do |open_assignment|
              # Grab Developer
              developer = "*" + open_assignment["developer"] + "*\n"
              message += developer
              # Grab Assignments
              assignments = open_assignment["assignments"]
              assignments.each do |assigment|
                task = "_" + assigment["task_title"]
                project = assigment["project"] + "_"
                task_link = assigment["task_link"]

                message += task + " (" + project + ")" + "\n" + $SETTINGS["DEVBOARD_URL"] + task_link + "\n"
              end # end assignment loop
              message += "\n"
            end  # end open_assignments loop
          else
            message = "No assignments."
          end # end openassignments if
        else
          message = "No results found."
        end # end results if
      else
        message = "Unable to connect to DevBoard due to a " + response.code + " error."
      end # end if

      return message
    end

  end
end
