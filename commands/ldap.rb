require 'ldap'

module ChatBotCommand
  class Ldap
    TITLE = "LDAP"
    REGEX = /^ldap/
    COMMAND = "ldap <individual>"
    DESCRIPTION = "Searches campus LDAP for information about a given individual."

    LDAP_MAX_RESULTS = 10

    # LDAP escape code credit: ruby-net-ldap (https://github.com/ruby-ldap/ruby-net-ldap).
    LDAP_ESCAPES = {
      "\0" => '00', # NUL            = %x00 ; null character
      '*'  => '2A', # ASTERISK       = %x2A ; asterisk ("*")
      '('  => '28', # LPARENS        = %x28 ; left parenthesis ("(")
      ')'  => '29', # RPARENS        = %x29 ; right parenthesis (")")
      '\\' => '5C', # ESC            = %x5C ; esc (or backslash) ("\")
    }
    # Compiled character class regexp using the keys from the above hash.
    LDAP_ESCAPE_RE = Regexp.new(
      "[" +
      LDAP_ESCAPES.keys.map { |e| Regexp.escape(e) }.join +
      "]")

    # Escape a string for use in an LDAP filter
    def ldap_escape(string)
      string.gsub(LDAP_ESCAPE_RE) { |char| "\\" + LDAP_ESCAPES[char] } if string
    end

    # Hides the ugly string logic used in determining if an LDAP field exists
    # Returns field if it exists, "Not listed" if it doesn't, and nil if ldap_entry is invalid
    def retrieve_field(ldap_entry, field)
      return nil if ldap_entry.nil?
      ldap_entry.get_values(field).to_s[2..-3].nil? ? "Not listed" : ldap_entry.get_values(field).to_s[2..-3]
    end

    def run(message, channel, private_allowed)
      parameters = message[5..-1] # Strip away the beginning "ldap "

      # In case we're called with less than five characters in 'message'
      return "No results found." if parameters == nil

      # LDAP attribute to search; nil will imply all supported fields
      ldap_field = nil

      # First, determine if we're doing an attribute-specific or general search
      field_match = /^[\S]+\s/.match(parameters)
      if field_match
        command = field_match[0].strip.downcase
        query = parameters[field_match[0].length..-1]

        case command
        when 'uid', 'login', 'loginid', 'kerberos'
          ldap_field = 'uid'
        when 'name', 'displayname', 'fullname'
          ldap_field = 'displayName'
        when 'givenname', 'first', 'firstname'
          ldap_field = 'givenName'
        when 'sn', 'last', 'lastname'
          ldap_field = 'sn'
        when 'mail', 'email', 'e-mail'
          ldap_field = 'mail'
        when 'department', 'dept', 'ou'
          ldap_field = 'ou'
        when 'title'
          ldap_field = 'title'
        when 'phone', 'telephone'
          ldap_field = 'telephoneNumber'
        when 'affiliation', 'ucdpersonaffiliation'
          ldap_field = 'ucdPersonAffiliation'
        else
          # Multiple words but no known commands. Use CN wildcard strategy.
          words = parameters.split

          words.map!{ |w| ldap_escape( ChatBotCommand.decode_slack(w) ) }

          search_terms = "(cn=*" + words.join("*") + "*)"
        end
      else
        # No specific command was given, the query is all given text
        query = parameters
      end

      # Connect to LDAP
      conn = LDAP::SSLConn.new( $SETTINGS['LDAP_HOST'], $SETTINGS['LDAP_PORT'].to_i )
      conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
      conn.bind(dn = $SETTINGS['LDAP_BASE_DN'], password = $SETTINGS['LDAP_BASE_PW'] )

      # search_terms is set if the query string needs to be more complex than a simply multi-attribute search,
      # such as the first+last name case handled above.
      unless search_terms
        # Set up LDAP search string for attribute-specific or broad-based search

        # Decode any Slack formatting
        query = ChatBotCommand.decode_slack(query)

        # Avoid LDAP injection attacks, thanks John Knoll
        query = ldap_escape(query)

        if ldap_field
          search_terms = "(|(#{ldap_field}=#{query}))"
        else
          search_terms = "(|(uid=#{query})(mail=#{query})(givenName=#{query})(sn=#{query})(cn=#{query}))"
        end
      end

      results = ""
      result_count = 0

      conn.search($SETTINGS['LDAP_SEARCH_DN'], LDAP::LDAP_SCOPE_SUBTREE, search_terms) do |entry|
        if result_count > 0
          results += "\n"
        end

        result_count = result_count + 1

        name = retrieve_field(entry, 'displayName')
        loginid = retrieve_field(entry, 'uid')
        mail = retrieve_field(entry, 'mail')
        office = retrieve_field(entry, 'street')
        phone = retrieve_field(entry, 'telephoneNumber')
        department = retrieve_field(entry, 'ou')
        departmentCode = retrieve_field(entry, 'ucdAppointmentDepartmentCode')
        title = retrieve_field(entry, 'title')

        # Note: Some individuals have multiple affiliations or may be missing affiliations
        affiliations = []
        entry.get_values('ucdPersonAffiliation').each do |affiliation_name|
          affiliations << affiliation_name
        end

        affiliations = (affiliations.length == 0 ? "Not listed" : affiliations = affiliations.join(", "))

        results += "*Name* #{name}\n"
        results += "*Login ID* #{loginid}\n"
        results += "*E-Mail* #{mail}\n"
        results += "*Department* #{department} (#{departmentCode})\n"
        results += "*Title* #{title}\n"
        results += "*Office* #{office}\n"
        results += "*Telephone* #{phone}\n"
        results += "*Affiliation* #{affiliations}\n"
      end

      conn.unbind

      if result_count > LDAP_MAX_RESULTS
        return "Too many results (#{result_count}). Try narrowing your search."
      elsif result_count == 0
        return "No results found."
      else
        return results
      end
    end

    @@instance = Ldap.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
