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
      response = get_information message.split(" ")[1]

      return response if response.class == String

      # Format information
      format_response response
    end

    # Returns formatted string of the user's mail forwarding information
    # @param data - an array of Nokogiri objects
    def format_response(data)
      return "No user found" unless !data.empty?
      response = []

      # Login ID
      value = data[1].text.split(" ")[2]
      response.push "*Login ID* #{value}"

      # Mail ID
      value = data[2].text.split(" ")[1]
      response.push "*Mail ID* #{value}"

      # Email
      value = data[3].text.split(" ")[1]
      response.push "*E-mail* #{value}"

      # IMAP
      value = data[4].text.split(" ").pop
      response.push "*IMAP* #{value}"

      # POP
      value = data[5].text.split(" ").pop
      response.push "*POP* #{value}"

      # SMTP
      value = data[6].text.split(" ").pop
      response.push "*SMTP* #{value}"

      return response.join("\n")
    end

    # Retrieves mail forwarding information from iet.ucdavis.edu
    # @param login_id - Kerberos login id to query
    # @return - an array of Nokogiri objects
    def get_information(login_id)
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
      page = agent.submit(mail_id_form, mail_id_form.buttons.first)

      unless page.code == "200"
        return "Could not complete the task due to " + page.code
      end

      return page.css("div.form-item.form-type-item")
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
