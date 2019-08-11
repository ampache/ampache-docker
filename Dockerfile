FROM ubuntu:18.04
MAINTAINER Afterster

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_PASS **Random**

ADD create_mysql_admin_user.sh run.sh /
ADD ampache.cfg.php.dist /var/temp/ampache.cfg.php.dist
ADD 001-ampache.conf /etc/apache2/sites-available/

RUN chmod 0755 /*.sh
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install wget
RUN echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.list

RUN wget -O - https://download.videolan.org/pub/debian/videolan-apt.asc|sudo apt-key add -
RUN apt-get update

RUN apt-get -y install inotify-tools mysql-server apache2 wget php5 php5-json php5-curl php5-mysqlnd pwgen lame libvorbis-dev vorbis-tools flac libmp3lame-dev libavcodec-extra* libfaac-dev libtheora-dev libvpx-dev libav-tools git

# Install composer for dependency management
RUN php -r "readfile('https://getcomposer.org/installer');" | php && \
    mv composer.phar /usr/local/bin/composer

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
