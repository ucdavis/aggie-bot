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

      # Format information
      format_information response
    end

    # Returns formatted string of the user's mail forwarding information
    # @param data - an array of Nokogiri objects
    def format_information(data)
      return "No user found" unless !data.empty?
      response = []

      # Login ID
      login_id = data[1].text.split(" ")
      title = login_id.shift(2).join(" ")
      value = login_id[0]
      response.push "*#{title}* \n>#{value}"

      # Mail ID
      mail_id = data[2].text.split(" ")
      title = mail_id[0]
      value = mail_id[1]
      response.push "*#{title}* \n>#{value}"

      # Email
      email = data[3].text.split(" ")
      title = email[0]
      value = email[1]
      response.push "*#{title}* \n>#{value}"

      # IMAP
      imap = data[4].text.split(" ")
      value = imap.pop
      title = imap.join(" ")
      response.push "*#{title}* \n>#{value}"

      # POP
      pop = data[5].text.split(" ")
      value = pop.pop
      title = pop.join(" ")
      response.push "*#{title}* \n>#{value}"

      # SMTP
      smtp = data[6].text.split(" ")
      value = smtp.pop
      title = smtp.join(" ")
      response.push "*#{title}* \n>#{value}"

      # Email Settings
      email_settings = data[7].text.split(" ")
      title = email_settings.shift(2).join(" ")
      value = email_settings.join(" ")
      response.push "*#{title}* \n>#{value}"

      return response.join("\n\n")
    end

    # Retrieves mail forwarding infomration from iet.ucdavis.edu
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
