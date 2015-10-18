FROM ruby
MAINTAINER think@hotmail.de

# TODO: activate --ngram
RUN \
  apt-get update && \
  apt-get install -y unzip default-jre && \
  gem install gherkin_language --no-format-exec && \
  echo "Feature: Empty" > /tmp/empty.feature && \
  gherkin_language /tmp/empty.feature && \
  rm /tmp/empty.feature 

CMD gherkin_language
