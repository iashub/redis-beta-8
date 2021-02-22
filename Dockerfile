FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive
ENV DATA_DIR /var/lib/redis/data
ENV PACKAGE_PATH /tmp/redis/redis.tar.gz
#ENV PACKAGE_URL 'https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/redis/redis-beta-8.tar.gz'
ENV PACKAGE_URL 'https://download.redis.io/releases/redis-beta-8.tar.gz'

RUN apt-get update -qq \
 && apt-get upgrade -yqq \
 && apt-get install -yqq \
    curl \
    build-essential \
 && apt-get autoremove --purge \
 && apt-get autoclean

ADD ${PACKAGE_URL} ${PACKAGE_PATH}
ADD recipes.sh /etc/redis/recipes.sh
ADD redis.conf /etc/redis/redis.conf
RUN /bin/bash -c '. /etc/redis/recipes.sh && redis.makeInstall'

WORKDIR /etc/redis

EXPOSE 6379

CMD [ "/usr/bin/redis-server", "/etc/redis/redis.conf" ]