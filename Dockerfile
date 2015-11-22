FROM ruby:2.2-onbuild

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN mkdir /shortener

WORKDIR /shortener

ADD Gemfile /shortener/Gemfile
ADD Gemfile.lock /shortener/Gemfile.lock

RUN bundle install
RUN gem install rubocop rubycritic

ADD . /shortener
