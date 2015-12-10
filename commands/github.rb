# is_number? credit: http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
def is_number?(string)
  true if Float(string) rescue false
end

def github_command(message)
  project_tag = nil
  issue_number = nil

  case message
  when /([\w]+)\/([\d]+)/ then # look for characters followed by / followed by numbers, e.g. dw/123
    matches = /([\w]+)\/([\d]+)/.match(message)
    project_tag = matches[1]
    issue_number = matches[2]
  end

  return "" unless project_tag
  return "" unless is_number?(issue_number)

  repo_url = nil

  # Ensure 'project_tag' exists in $GITHUB_SETTINGS
  $GITHUB_SETTINGS["GITHUB_PROJECTS"].each do |p|
    if p[project_tag]
      repo_url = p[project_tag]
      break
    end
  end

  return "No such project tag '#{project_tag}'" unless repo_url

  Octokit.auto_paginate = true
  client = Octokit::Client.new(:access_token => $GITHUB_SETTINGS["GITHUB_TOKEN"])
  client.login

  begin
    issue = client.issue(repo_url, issue_number)
  rescue Octokit::NotFound => e
    return "No such issue for for '#{project_tag}'"
  end

  return "*#{issue[:title]}* (#{issue[:state]})\n#{issue[:html_url]}"
end
