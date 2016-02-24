require 'slack-ruby-client'

def slack_connect api
  Slack.configure do |config|
    config.token = api
  end

  return Slack::RealTime::Client.new
end