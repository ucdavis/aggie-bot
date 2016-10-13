require "net/http"

module ChatBotCommand
  class Email
    TITLE = "Email"
    REGEX = /^!email\s+/
    COMMAND = "!email @user_name or !email username or !email name"
    DESCRIPTION = "Output the email address of the user"

    @users = Hash.new

    def run(message)
      # Generate a hash for querying
      generate_users_hash()

      queriedUsers = []
      case message
      when /^!email\s+(<\S+>)\s*$/ # query by @user
        # at this point, user is "<@SOMEID>"
        user = /^!email\s+(<\S+>)\s*$/.match(message)[1]

        # we only need SOMEID
        user = user[2...user.index(">")]
        queriedUsers.push(user)
      when /(\S+)/ # query by "msdiez" / "Mark Diez"
        # shift to remove !email
        query = message.scan(/(\S+)/)
        query.shift
        user = ""
        query.each do |item|
          user = user + item[0] + " "
        end

        # remove ending whitespace
        user.strip!

        # get possible users
        possibleUsers = @users.keys.grep(/#{user}/)
        queriedUsers.push(*possibleUsers)
      end

      response = ""
      queriedUsers.each do |user|
        response += ">" + user + ": " +  @users[user] + "\n"
      end

      return response.empty? ? "User does not exist" : response
    end # def run

    def generate_users_hash
      @users = Hash.new
      # Get a list of user data from slack api
      uri = URI.parse("https://slack.com/api/users.list")
      args = {token: $SETTINGS["SLACK_API_TOKEN"]}
      uri.query = URI.encode_www_form(args)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if response.code == "200"
        result = JSON.parse(response.body)
        users = result["members"]
        users.each do |user|
          username = user["name"]
          userId = user["id"]
          userFullName = user["real_name"]
          userEmail = user["profile"]["email"]

          @users[userId] = userEmail
          @users[username] = userEmail
          @users[userFullName] = userEmail
        end
      else
        $logger.error "Could not connect to Slack API due to #{response.code}"
        return "Could not connect to Slack API due to #{response.code}"
      end
    end # def generate_user_array
  end # class Email
end # module ChatBotCommand
