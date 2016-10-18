require "net/http"

module ChatBotCommand
  class Iam
    TITLE = "IAM"        # Title of the command
    REGEX = /^!iam/      # REGEX the command needs to look for
    COMMAND = "!iam <login_id>"     # Command to use
    DESCRIPTION = "Searches campus IAM for information about a given individual."       # Description of the command

    def run(message, channel)
      # Grab the query to run for IAM
      query = message.scan(/(\S+)/)
      query.shift # gets rid of !iam

      iam_id = get_iam_id(query)
      response = gather_data(iam_id)

      return format_data(response)
    end


    def get_iam_id query

    end

    def gather_data iam_id

    end

    def format_data data

    end

    def generate_users_hash
      # @users = Hash.new
      # # Get a list of user data from slack api
      # uri = URI.parse("https://slack.com/api/users.list")
      # args = {token: $SETTINGS["SLACK_API_TOKEN"]}
      # uri.query = URI.encode_www_form(args)
      # http = Net::HTTP.new(uri.host, uri.port)
      # http.use_ssl = true
      # request = Net::HTTP::Get.new(uri.request_uri)
      # response = http.request(request)
      #
      # if response.code == "200"
      #   result = JSON.parse(response.body)
      #   users = result["members"]
      #   users.each do |user|
      #     username = user["name"]
      #     user_id = user["id"]
      #     user_full_name = user["real_name"]
      #     user_email = user["profile"]["email"]
      #
      #     @users[user_id] = user_email
      #     @users[username] = user_email
      #     @users[user_full_name] = user_email
      #   end
      # else
      #   $logger.error "Could not connect to Slack API due to #{response.code}"
      #   return "Could not connect to Slack API due to #{response.code}"
      # end
    end # def generate_user_array

    # Essential to make commands a singleton
    @@instance = Iam.new
    def self.get_instance
      return @@instance
    end

    # Avoids any "accidental" call to new outside of the class
    private_class_method :new
  end
end
