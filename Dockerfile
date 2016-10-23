FROM ruby
MAINTAINER think@hotmail.de

ENV VERSION=8 UPDATE=91 BUILD=14
ENV JAVA_HOME=/usr/lib/jvm/java-${VERSION}-oracle

RUN apt-get update && apt-get install -y \
  git \
  cmake \
  build-essential \
  libgtk2.0-dev \
  libnss3-dev \
  libgconf-2-4 \
  libxss-dev \
  libasound2-dev \
  libxtst-dev \
  libgl1-mesa-dev \
  unzip

RUN curl --silent --location --retry 3 --cacert /etc/ssl/certs/GeoTrust_Global_CA.pem \
         --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
         http://download.oracle.com/otn-pub/java/jdk/"${VERSION}"u"${UPDATE}"-b"${BUILD}"/jdk-"${VERSION}"u"${UPDATE}"-linux-x64.tar.gz \
    | tar xz -C /tmp && \
    mkdir -p /usr/lib/jvm && mv /tmp/jdk1.${VERSION}.0_${UPDATE} "${JAVA_HOME}"

RUN update-alternatives --install "/usr/bin/java" "java" "${JAVA_HOME}/bin/java" 1 \
    && update-alternatives --install "/usr/bin/javaws" "javaws" "${JAVA_HOME}/bin/javaws" 1 \
    && update-alternatives --install "/usr/bin/javac" "javac" "${JAVA_HOME}/bin/javac" 1 \
    && update-alternatives --install "/usr/bin/jar" "jar" "${JAVA_HOME}/bin/jar" 1 \
    && update-alternatives --set java "${JAVA_HOME}/bin/java" \
    && update-alternatives --set javaws "${JAVA_HOME}/bin/javaws" \
    && update-alternatives --set javac "${JAVA_HOME}/bin/javac" \
    && update-alternatives --set jar "${JAVA_HOME}/bin/jar"

# TODO: activate --ngram
RUN \
  gem install gherkin_language --no-format-exec && \
  echo "Feature: Empty" > /tmp/empty.feature && \
  gherkin_language /tmp/empty.feature && \
  rm /tmp/empty.feature 

CMD gherkin_language
