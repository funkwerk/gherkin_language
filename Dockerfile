FROM frolvlad/alpine-oraclejdk8:slim

MAINTAINER think@hotmail.de

# TODO: activate --ngram
RUN apk --update add ruby ruby-dev build-base ruby-rdoc ruby-irb ca-certificates openssl \
 && gem install gherkin_language json --no-format-exec \
 && echo "Feature: Empty" > /tmp/empty.feature \
 && gherkin_language /tmp/empty.feature \
 && rm /tmp/empty.feature \
 && apk del ruby-dev build-base ruby-rdoc ruby-irb ca-certificates openssl \
 && rm -rf /var/cache/apk \
 && ls -1 /tmp/LanguageTool*/org/languagetool/resource/ | grep -v en | xargs rm -rf /tmp/LanguageTool*/org/languagetool/resource/

ENTRYPOINT ["gherkin_language"]
CMD ["--help"]
