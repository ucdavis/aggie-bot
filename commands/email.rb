require "net/http"

module ChatBotCommand
  class Email
    TITLE = "Email"
    REGEX = /^!email\s+(<\S+>)\s*$/
    COMMAND = "!email @user_name"
    DESCRIPTION = "Output the email address of the user"

    def run(message)
      # at this point, user is "<@SOMEID>"
      user = REGEX.match(message)[1]

      # we only need SOMEID
      endIndex = user.index(">")
      user = user[2...endIndex]

      # Get user data from slack api
      uri = URI.parse("https://slack.com/api/users.info")
      args = {token: $SETTINGS["SLACK_API_TOKEN"], user: user}
      uri.query = URI.encode_www_form(args)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if response.code == "200"
        result = JSON.parse(response.body)
        return result["user"]["profile"]["email"]
      else
        return "Could not connect to Slack API due to #{response.code}"
      end
    end
  end
end
