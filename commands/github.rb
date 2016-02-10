# is_number? credit: http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
def is_number?(string)
  true if Float(string) rescue false
end

def github_command(message)
  messages = []
  matches = nil

  case message
  # look for characters at the beginning of the line or following a space
  # followed by / followed by numbers, e.g. dw/123
  when /(^|\s)([\w]+)\/([\d]+)/ then
    matches = message.scan(/(^|\s)([\w]+)\/([\d]+)/)
  end

  return "" unless matches

  matches.each do |m|
    repo_url = nil
    issue = nil
    project_tag = m[1]
    issue_number = m[2]

    # Ensure 'project_tag' exists in $GITHUB_SETTINGS
    $GITHUB_SETTINGS["GITHUB_PROJECTS"].each do |p|
      if p[project_tag]
        repo_url = p[project_tag]
        break
      end
    end

    messages.push "No such project tag '#{project_tag}'" unless repo_url

    # if repo url does exist, then find the issue
    if repo_url
      Octokit.auto_paginate = true
      client = Octokit::Client.new(:access_token => $GITHUB_SETTINGS["GITHUB_TOKEN"])
      client.login

      begin
        issue = client.issue(repo_url, issue_number)
      rescue Octokit::NotFound => e
        messages.push "No such issue for for '#{project_tag}'"
      end
    end
    
    if (repo_url && issue)
      messages.push "*#{issue[:title]}* (#{issue[:state]})\n#{issue[:html_url]}"
    end
  end

  return messages
end
