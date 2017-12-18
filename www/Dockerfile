#FROM ruby:2.3.6
#RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

FROM ruby:2.3.6-alpine3.4
RUN apk --update --upgrade add tzdata nodejs postgresql-dev postgresql-client curl git libxml2-dev libxslt-dev build-base # imagemagick
RUN rm /var/cache/apk/*

RUN mkdir /app
WORKDIR /app
COPY . /app
