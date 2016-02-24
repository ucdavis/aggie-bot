require 'json'
require 'net/http'
require 'net/https'

# Get data from Devboard
def devboard_command
  uri =  URI.parse($SETTINGS["DEVBOARD_JSON"])

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if uri.scheme == "https" 
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth $SETTINGS["DEVBOARD_API_USER"], $SETTINGS["DEVBOARD_API_SECRET"]

  response = http.request(request)

  # Proper Credentials met
  message = ""
  if response.code == "200"
    result = JSON.parse(response.body)
    open_assignments = result["open_assignments"]
    
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
    end # end open_assignments loop
  end # end if
  
  return message #redundant ?
end