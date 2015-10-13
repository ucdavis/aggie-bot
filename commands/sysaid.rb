# is_number? credit: http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
def is_number?(string)
  true if Float(string) rescue false
end

def sysaid_command(message)
  ticket_id = nil

  case message
  when /^sysaid/i then
    ticket_id = message[/\d+/]
  when /#[\d]+(\s|$|\z|\D)/ then # looks for #123 followed by space, end of string, or end of line
    matches = /#([\d]+)(\s|$|\z|\D)/.match(message)
    ticket_id = matches[1] if matches
  end

  #puts "sysaid_command: ticket_id is '#{ticket_id}'"
  #puts "sysaid_command: is_number? is #{is_number?(ticket_id)}"

  return "" unless ticket_id
  return "" unless is_number?(ticket_id)

  link = "https://sysaid.dss.ucdavis.edu/index.jsp#/SREdit.jsp?QuickAcess&id=" + ticket_id # link template for a SysAid ticket given ID

  # Find ticket in SysAid
  ticket = SysAid::Ticket.find_by_id(ticket_id)
  if ticket.nil?
    # Ticket does not exist.
    return "Couldn't find a ticket with ID #{ticket_id}"
  else
    # Ticket exists, compose 'reply_message'
    return "*#{ticket.title}* requested by *#{ticket.request_user}*: #{link}"
  end
end
