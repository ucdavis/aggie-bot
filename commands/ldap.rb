LDAP_MAX_RESULTS = 8

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

##
# Escape a string for use in an LDAP filter
def ldap_escape(string)
  string.gsub(LDAP_ESCAPE_RE) { |char| "\\" + LDAP_ESCAPES[char] }
end

def ldap_command(message)
  # First, we need to check if the message contains an e-mail address as they
  # utilize a special encoding. If we cannot detect one, assume everything
  # except the beginning 'ldap ' is the search term.

  # (E-mail encoding sample: "<mailto:somebody@ucdavis.edu|somebody@ucdavis.edu>")
  mail_match = /mailto:([\S]+)\|/.match(message)

  if mail_match
    term = mail_match[1]
  else
    term = message[5..-1]
  end

  # Avoid LDAP injection attacks, thanks John Knoll
  term = ldap_escape(term)

  # Connect to LDAP
  conn = LDAP::SSLConn.new( $SETTINGS['LDAP_HOST'], $SETTINGS['LDAP_PORT'].to_i )
  conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
  conn.bind(dn = $SETTINGS['LDAP_BASE_DN'], password = $SETTINGS['LDAP_BASE_PW'] )

  search_terms = "(|(uid=#{term})(mail=#{term})(givenName=#{term})(sn=#{term})(cn=#{term}))"
  results = ""
  result_count = 0

  conn.search($SETTINGS['LDAP_SEARCH_DN'], LDAP::LDAP_SCOPE_SUBTREE, search_terms) do |entry|
    if result_count > 0
      results += "\n"
    end

    result_count = result_count + 1

    unless entry.get_values('displayName').to_s[2..-3].nil?
      name = entry.get_values('displayName').to_s[2..-3]
    else
      name = "Not listed"
    end
    unless entry.get_values('uid').to_s[2..-3].nil?
      loginid = entry.get_values('uid').to_s[2..-3]
    else
      loginid = "Not listed"
    end
    unless entry.get_values('mail').to_s[2..-3].nil?
      mail = entry.get_values('mail').to_s[2..-3]
    else
      mail = "Not listed"
    end
    unless entry.get_values('street').to_s[2..-3].nil?
      office = entry.get_values('street').to_s[2..-3]
    else
      office = "Not listed"
    end
    unless entry.get_values('ou').to_s[2..-3].nil?
      department = entry.get_values('ou').to_s[2..-3]
    else
      department = "Not listed"
    end

    affiliations = []
    # A person may have multiple affiliations
    entry.get_values('ucdPersonAffiliation').each do |affiliation_name|
      affiliations << affiliation_name
    end
    if affiliations.length == 0
      affiliations = "Not listed"
    else
      affiliations = affiliations.join(", ")
    end

    results += "*Name* #{name}\n"
    results += "*Login ID* #{loginid}\n"
    results += "*E-Mail* #{mail}\n"
    results += "*Department* #{department}\n"
    results += "*Office* #{office}\n"
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
