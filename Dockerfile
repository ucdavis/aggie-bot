FROM ruby:2.3

# Install necessary libraries
RUN apt-get update
RUN apt-get install libsasl2-dev
RUN apt-get install libssl-dev
RUN apt-get install -y libldap2-dev

# Install gems
ADD Gemfile* ./
RUN gem install ruby-ldap -v '0.9.17'
RUN bundle install

# Add ChatBot files
ADD . ./

# Run chatbot
CMD ["./dss-chatbot.rb", "run"]
