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
                + "example: `!iam email trex@ucdavis.edu`"

    def run(message, channel)
      # Grab the query to run for IAM
      query = message.scan(/(\S+)/)
      query.shift # gets rid of !iam

      iam_id = get_iam_id(query)
      response = gather_data(iam_id)

      return format_data(response)
    end

    # Returns the iam id of the query, a string otherwise
    # @param query - Slack message without !iam
    def get_iam_id query
      command = query.shift
      command = command[0].downcase # required since shift returns an array
      iam_id = -1

      case command
      when "name"
      when "first"
      when "last"
      when "iamid"
      when "loginid"
      when "email"
      else
        return command + " is not a valid option. !help iam for more details"
      end

      return iam_id
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
