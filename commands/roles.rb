module ChatBotCommand
  class Roles
    TITLE = "Roles"
    REGEX = /^roles [\S]+$/i
    COMMAND = "roles <user>"
    DESCRIPTION = "Checks Roles Management for the roles of a user and outputs it"

    def roles_client
      @roles_client ||= RolesManagementAPI.login($SETTINGS['ROLES_URL'], $SETTINGS['ROLES_USERNAME'], $SETTINGS['ROLES_TOKEN'])
    end

    def run(loginid, channel)
      if roles_client.connected?
        p = roles_client.find_person_by_loginid(loginid)

        if (p == nil) || (p.role_assignments == nil) || (p.role_assignments.length == 0)
          return "#{loginid} has no role assignments."
        end

        return "#{loginid} has the following role assignments: " + p.role_assignments.map{|ra| "(*#{ra[:application_name]}* / #{ra[:name]})"}.join(", ")
      else
        return "There was an error communicating with Roles Management."
      end
    end

    def self.get_instance
      @@instance ||= Roles.new
    end

    private_class_method :new
  end
end
