require 'rake'

namespace :autobot do
  desc 'Send !assignments message to slack at 9 am and 1 pm'
  task :remind => :environment do
    # Connect to slack
    # Send message
    # Disconnect from slack
  end
end