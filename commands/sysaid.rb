# is_number? credit: http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
def is_number?(string)
  true if Float(string) rescue false
end

def sysaid_command(message)
  ticket_id = message[/\S+/] # ticket ID of the message

  puts "Ticket_id appears to be '#{ticket_id}'"

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
