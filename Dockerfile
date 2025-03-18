FROM ruby:3.1.4-alpine

RUN apk add --no-cache git && \
    apk add --no-cache openldap-dev && \
    apk add --no-cache build-base && \
    apk add --no-cache bind-tools

# Set up environment to avoid adding files to root home
ENV HOME /home
WORKDIR $HOME

# Install gems
ADD Gemfile $HOME/
ADD Gemfile.lock $HOME/
RUN bundle install

# Set up chatbot environment
RUN mkdir $HOME/{commands}

# Add ChatBot files
ADD ./aggie_bot.rb $HOME/
ADD ./chat_bot_command.rb $HOME/
ADD ./settings.yml $HOME/

# Add Commands
ADD ./commands/* $HOME/commands/

# Redirect log to 'Docker log'
RUN ln -sf /dev/stdout $HOME/chatbot.log

# Run chatbot
ENTRYPOINT ["./aggie_bot.rb", "run"]
