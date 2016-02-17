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

  return "" unless ticket_id
  return "" unless is_number?(ticket_id)

  # Link template for a SysAid ticket given ID
  link = "https://sysaid.dss.ucdavis.edu/index.jsp#/SREdit.jsp?QuickAcess&id=" + ticket_id

  # Find ticket in SysAid
  begin
    ticket = SysAid::Ticket.find_by_id(ticket_id)

    if ticket.nil?
        # Ticket does not exist.
        return "Couldn't find a ticket with ID #{ticket_id}"
    else
        # Ticket exists, compose 'reply_message'
        return "*#{ticket.title}* requested by *#{ticket.request_user}*: #{link}"
    end
  rescue SysAidException => e
    return "Error while communicating with SysAid. Try again later."
  end
end
