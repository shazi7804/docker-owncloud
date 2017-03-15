# The Dockerfile for owncloud
# Author: shazi7804

# pull base image
FROM ubuntu:16.04
MAINTAINER shazi7804@gmail.com

ENV DOMAIN cloud.shazi.info
ENV OWNCLOUD_VERSION 9.0.8

# path
ENV SSLPATH=/opt/ssl
ENV SSLCERT=${SSLPATH}/${DOMAIN}.crt \
    SSLKEY=${SSLPATH}/${DOMAIN}.key \
    WWWROOT=/var/www/owncloud

# db
ENV ROOT_DBPWD="ao3eji62jo45;3" ＼
    OWNCLOUD_DBNAME="owncloud" \
    OWNCLOUD_DBUSER="owncloud_USER" \
    OWNCLOUD_DBPWD="owncloud_PWD" \
    OWNCLOUD_DB="localhost"

# ssl
ENV COUNTRY=TW \
    STATE=Taiwan \
    LOCALITY=Taipei \
    COMPANY=shazi.info \
    UNIT=Tech \
    EMAIL=shazi7804@gmail.com 

# packages
RUN set -xe && export DEBIAN_FRONTEND=noninteractive &&\
      apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
        wget curl unzip openssl vim \
        apache2 \
        percona-server-server \
        php7.0 php7.0-common libapache2-mod-php7.0 php7.0-gd \
        php-xml-parser php7.0-json php7.0-curl php7.0-bz2 php7.0-zip \
        php7.0-mcrypt php7.0-mysql php7.0-mbstring memcached php-memcached \
        php-redis redis-server

RUN mkdir -p /opt/docker-setup
COPY script /opt/docker-setup
RUN chmod +x /opt/docker-setup/*.sh

RUN /opt/docker-setup/init.sh

RUN /opt/docker-setup/owncloud.sh

RUN a2ensite ${DOMAIN}.conf
RUN chown -R www-data:www-data $WWWROOT

EXPOSE 80 443
ENTRYPOINT /opt/docker-setup/bootstrap.sh && bash