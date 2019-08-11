FROM ubuntu:18.04
MAINTAINER Afterster

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_PASS **Random**

ADD create_mysql_admin_user.sh run.sh /
ADD ampache.cfg.php.dist /var/temp/ampache.cfg.php.dist
ADD 001-ampache.conf /etc/apache2/sites-available/

RUN chmod 0755 /*.sh
RUN apt-get -q -q update
RUN apt-get -q -q -y install wget gnupg ca-certificates
RUN echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.list
RUN wget -qO - https://download.videolan.org/pub/debian/videolan-apt.asc | apt-key add -
RUN apt-get -q -q update
RUN apt-get -q -q -y upgrade
RUN apt-get -q -q -y install inotify-tools mysql-server apache2 php php-json php-curl php-mysql composer pwgen lame libvorbis-dev vorbis-tools flac libmp3lame-dev libavcodec-extra libfaac-dev libtheora-dev libvpx-dev ffmpeg git cron

# For local testing / faster builds
# COPY master.tar.gz /opt/master.tar.gz
ADD https://github.com/ampache/ampache/archive/master.tar.gz /opt/ampache-master.tar.gz

# extraction / installation
RUN rm -rf /var/www/* && \
    tar -C /var/www -xf /opt/ampache-master.tar.gz ampache-master --strip=1 && \
    cd /var/www && composer install --prefer-source --no-interaction && \
    chown -R www-data /var/www

# setup mysql like this project does it: https://github.com/tutumcloud/tutum-docker-mysql
# Remove pre-installed database

RUN rm -rf /var/lib/mysql/*

# setup apache with default ampache vhost
RUN rm -rf /etc/apache2/sites-enabled/*
RUN ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite

# Add job to cron to clean the library every night
RUN echo '30 7    * * *   www-data php /var/www/bin/catalog_update.inc' >> /etc/crontab

VOLUME ["/etc/mysql", "/var/lib/mysql", "/media", "/var/www/config", "/var/www/themes"]
EXPOSE 80

CMD ["/run.sh"]
