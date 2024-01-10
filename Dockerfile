FROM ruby:3.1.2

RUN apt-get update -qq
RUN apt-get -y install cron

ENV APP_APTH=/usr/src
WORKDIR $APP_APTH

COPY Gemfile* .
COPY . $APP_PATH

RUN bundle install
