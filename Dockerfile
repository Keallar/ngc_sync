FROM ruby:3.1.2

RUN apt-get update -qq

ENV APP_APTH=/usr/src
WORKDIR $APP_APTH

ADD Gemfile $APP_APTH/Gemfile
ADD Gemfile.lock $APP_APTH/Gemfile.lock

RUN bundle install
