source 'https://rubygems.org'

gem 'ruby-ldap'            # for LDAP integration
gem 'daemons'              # for 'daemon-izing' the script
gem 'hashie', '=3.4.5'     # temporarily hold hashie (used by slack-ruby-client) at 3.4.5 until a 3.5.1 bug gets fixed
gem 'slack-ruby-client'    # for Slack support

gem 'eventmachine'         # required by slack-ruby-client
gem 'faye-websocket'       # required by slack-ruby-client

# For Roles Management support
gem 'roles-management-api', git: "https://github.com/dssit/roles-management-api.git"

# For GitHub support
gem 'octokit'
gem 'faraday-http-cache' # (provides etag caching in octokit)

# For cron tasks
gem 'whenever', :require => false

# For crawling with Mail ID command
gem 'mechanize'
