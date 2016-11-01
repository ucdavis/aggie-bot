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
      response = fetch_mail_settings message.split(" ")[1]

      return response if response.class != Nokogiri::XML::NodeSet

      # Format information
      format_response response
    end

    # Returns formatted string of the user's mail forwarding information
    # @param data - an array of Nokogiri objects
    def format_response(data)
      return "No user found" if data.empty?
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
    def fetch_mail_settings(login_id)
      # Success! Load the page and use the CAS credentials
      agent = Mechanize.new

      # Certain web servers check the user agent string for compatibility
      agent.user_agent_alias = 'Mac Firefox'

      begin
        # Run Mail ID lookup
        page = agent.get('https://iet.ucdavis.edu/itprovider')

        # Find Mail ID form
        mail_id_form = nil
        page.forms.each do |form|
          if (form["form_id"] == "ucde_email_id_detective_form_block")
            mail_id_form = form
          end
        end

        if mail_id_form == nil
          $logger.error "Mail ID information not found. Did the page format change?"
          return "Could not fetch Mail ID information due to error finding the proper form"
        end

        # Fill form
        mail_id_form.fields[0].value = login_id

        # Submit Form
        page = agent.submit(mail_id_form, mail_id_form.buttons.first)
      rescue SocketError
        $logger.error "Could not fetch Mail ID information due to error loading the webpage. Did the link change?"
        return "Could not fetch Mail ID information due to error loading the webpage"
      else
        unless page.code == "200"
          $logger.warn "Could not fetch Mail ID information due to error while reading webpage. Received code:  " + page.code
          return "Could not fetch Mail ID information due to error while reading webpage. Received code:  " + page.code
        end

        forwarding_info = page.css("div.form-item.form-type-item")
        # TODO: forwarding_info is empty if the user does not exist or the css is not found on the page
        #     : figure out how to distinguish
        # unless forwarding_info.empty?
        #   return forwarding_info
        # else
        #   $logger.error "Mail ID information not found. Page layout not recognized."
        #   return "Mail ID information not found. Page layout not recognized."
        # end
      end
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
