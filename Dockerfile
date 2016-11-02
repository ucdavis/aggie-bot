#FROM ubuntu:latest
#MAINTAINER Mark Emmanuel Diez <msdiez@ucdavis.edu>
#RUN apt-get update && apt-get install -y ruby ruby-dev
#RUN gem install bundler
#RUN bundle install
#RUN ./dss-chatbot.rb run

FROM ruby:2.3
ENV HOME /home/chatbot
RUN apt-get update
RUN apt-get install libsasl2-dev
RUN apt-get install libssl-dev
RUN apt-get install -y libldap2-dev
WORKDIR $HOME
ADD Gemfile* $HOME/
RUN gem install ruby-ldap -v '0.9.17'
RUN bundle install
ADD . $HOME
CMD ["./dss-chatbot.rb", "run"]
