require 'octokit'

module ChatBotCommand
  class GitHub
    TITLE = "GitHub"
    REGEX = /([\w]+)\/([\d]+)/ # look for characters followed by / followed by numbers, e.g. dw/123
    COMMAND = "{repository}/{issue_number}"
    DESCRIPTION = "Outputs the issue from github"

    def run(message, channel, private_allowed)
      unless $SETTINGS["GITHUB_TOKEN"]
        $logger.error "Cannot run GitHub command: ensure GITHUB_TOKEN is in settings."
        return "GitHub support not correctly configured."
      end

      messages = []
      matches = nil

      case message
      # look for characters at the beginning of the line or following a space
      # followed by / followed by numbers, e.g. dw/123
      when /(^|\s)([\w]+)\/([\d]+)/ then
        matches = message.scan(/(^|\s)([\w]+)\/([\d]+)/)
      end

      return [] unless matches

      begin
        Octokit.auto_paginate = true
        client = Octokit::Client.new(:access_token => $SETTINGS["GITHUB_TOKEN"])
        client.login
      rescue Octokit::Unauthorized => e
        $logger.error "Unable to log into GitHub. Check credentials."
        return "Cannot run GitHub command, credentials rejected."
      end

      matches.each do |m|
        repo_url = nil
        issue = nil
        project_tag = m[1]
        issue_number = m[2]

        # Ensure 'project_tag' exists in $SETTINGS
        $SETTINGS["GITHUB_PROJECTS"].each do |p|
          if p[project_tag]
            repo_url = p[project_tag]
            break
          end
        end

        unless repo_url
          # No such project. Don't emit anything.
          # messages.push "No such project tag '#{project_tag}'"
        else
          # if repo url does exist, then find the issue
          begin
            issue = client.issue(repo_url, issue_number)
            messages.push "*#{issue[:title]}* (#{issue[:state]})\n#{issue[:html_url]}"
          rescue Octokit::NotFound => e
            messages.push "No such issue for for '#{project_tag}'"
          end
        end
      end

      return messages.join("\n")
    end

    @@instance = GitHub.new
    def self.get_instance
      return @@instance
    end

    private_class_method :new
  end
end
