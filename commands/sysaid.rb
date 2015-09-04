def sysaid_command(message)
  ticket_id = message[/\d+/] # ticket ID of the message

  return "" unless ticket_id

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
