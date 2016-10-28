require "net/http"

module ChatBotCommand
  class Email
    TITLE = "Email"
    REGEX = /^!email\s+/
    COMMAND = "!email @user_name or !email username or !email name"
    DESCRIPTION = "Output the email address of the user"

    @users = Hash.new

    def run(message, channel)
      # Generate a hash for querying
      generate_users_hash()

      queried_users = []
      case message
      when /^!email\s+(<\S+>)\s*$/ # query by @user
        # at this point, user is "<@SOMEID>"
        user = /^!email\s+(<\S+>)\s*$/.match(message)[1]

        # we only need SOMEID
        user = user[2...user.index(">")]
        queried_users.push(user)
      else /(\S+)/ # query by "msdiez" / "Mark Diez"
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
        possible_users = @users.keys.grep(/#{user}/)
        queried_users.push(*possible_users)
      end

      response = ""
      queried_users.each do |user|
        response += ">" + user + ": " +  @users[user] + "\n"
      end

      return response.empty? ? "User does not exist" : response
    end # def run

    # Returns a hash of :user => email of all users in the team else a string
    def generate_users_hash
      @users = Hash.new

      # Get a list of user data from slack api
      result = ChatBotCommand.slack_api("users.list", {})

      unless result == nil
        users = result["members"]
        users.each do |user|
          username = user["name"]
          user_id = user["id"]
          user_full_name = user["real_name"]
          user_email = user["profile"]["email"]

          @users[user_id] = user_email
          @users[username] = user_email
          @users[user_full_name] = user_email
        end
      end
    end # def generate_user_array

    @@instance = Email.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end # class Email
end # module ChatBotCommand
