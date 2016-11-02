FROM ruby:2.3

# Install necessary libraries
RUN apt-get update
RUN apt-get install libsasl2-dev
RUN apt-get install libssl-dev
RUN apt-get install -y libldap2-dev
RUN apt-get install -y gnome-schedule

# Set up environment to avoid adding files to root home
ENV HOME /home
WORKDIR $HOME

# Install gems
ADD Gemfile $HOME/
ADD Gemfile.lock $HOME/
RUN bundle install

# Set up chatbot environment
RUN mkdir $HOME/config
RUN mkdir $HOME/commands

# Add ChatBot files
ADD ./dss-chatbot.rb $HOME/
ADD ./chat_bot_command.rb $HOME/
ADD ./config/schedule.rb $HOME/config
ADD ./config/settings.yml $HOME/config

# Add Commands
ADD ./commands/devboard.rb $HOME/commands
ADD ./commands/email.rb $HOME/commands
ADD ./commands/github.rb $HOME/commands
ADD ./commands/help.rb $HOME/commands
ADD ./commands/host.rb $HOME/commands
ADD ./commands/iam.rb $HOME/commands
ADD ./commands/ldap.rb $HOME/commands
ADD ./commands/mail.rb $HOME/commands
ADD ./commands/roles.rb $HOME/commands
ADD ./commands/visioneers.rb $HOME/commands

# Update crontab from whenever gem
RUN whenever --update-crontab

# Run chatbot
ENTRYPOINT ["./dss-chatbot.rb", "run"]
