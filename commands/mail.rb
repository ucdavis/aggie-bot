require 'mechanize'

module ChatBotCommand
  class Mail
    TITLE = "Mail ID"
    REGEX = /^!mailid\s+\S+\s*$/
    COMMAND = "!mailid <Login ID>"
    DESCRIPTION = "Shows the mail forwarding information of a user e.g. `!mailid cmthielen`"

    # Run MUST return a string
    def run(message, channel)
      # Get information
      # Format information
      return "TODO"
    end

    # Retrieves mail forwarding infomration from iet.ucdavis.edu
    # @param login_id - Kerberos login id to query
    # @return - hash containing the information, else a string
    def get_information login_id
      # Success! Load the page and use the CAS credentials
      agent = Mechanize.new

      # Certain web servers check the user agent string for compatibility
      agent.user_agent_alias = 'Mac Firefox'

      # Run Mail ID lookup
      page = agent.get('https://iet.ucdavis.edu/itprovider')

      # Find form TODO: try to see if we can find it dynamically?
      mail_id_form = page.forms[2]

      # Fill form
      mail_id_form.fields[0].value = login_id

      # Submit Form
      page = agent.submit(form, form.buttons.first)

      unless page.code == "200"
        return "Could not complete the task due to " + page.code
      end

      return page.body
    end

    # Essential to make commands a singleton
    @@instance = Mail.new
    def self.get_instance
      return @@instance
    end

    # Avoids any "accidental" call to new outside of the class
    private_class_method :new
  end
end
