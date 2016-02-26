require 'rake'
require 'yaml'
require 'slack-ruby-client'


namespace :autobot do
  desc 'Posts the assignment(s) of each developer'
  task :remind do
    $cwd = Dir.getwd
    require $cwd + "/commands/devboard.rb"
    
    # Set up settings
    settings_file = $cwd + '/config/settings.yml'
    $SETTINGS = YAML.load_file(settings_file)

    # Connect to slack
    Slack.configure do |config|
      config.token = $SETTINGS["SLACK_API_TOKEN"]
    end

    # Send message
    client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
    client.chat_postMessage(channel: '#appdev', text: devboard_command , as_user: true)
  end
end