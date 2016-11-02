FROM ruby:2.3

# Install necessary libraries
RUN apt-get update
RUN apt-get install libsasl2-dev
RUN apt-get install libssl-dev
RUN apt-get install -y libldap2-dev

# Set up where ruby app will be stationed
# https://www.packet.net/blog/how-to-run-your-rails-app-on-docker/
ENV HOME /home/chatbot
WORKDIR $HOME
ADD Gemfile* $HOME/

# Install gems
RUN gem install ruby-ldap -v '0.9.17'
RUN bundle install
ADD . $HOME

# Run chatbot
CMD ["./dss-chatbot.rb", "run"]
