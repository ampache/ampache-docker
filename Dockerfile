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
RUN apt-get -q -q -y install inotify-tools mysql-server apache2 php php-json php-curl php-mysql composer libev-libevent-dev pwgen lame libvorbis-dev vorbis-tools flac libmp3lame-dev libfaac-dev libtheora-dev libvpx-dev libavcodec-extra ffmpeg git cron
RUN rm -rf /var/lib/mysql/* /var/www/* /etc/apache2/sites-enabled/* && \
    wget -qO - https://github.com/ampache/ampache/archive/master.tar.gz \
        | tar -C /var/www -xzf - ampache-master --strip=1 && \
    cd /var/www && composer install --prefer-source --no-interaction && \
    chown -R www-data /var/www
RUN apt-get purge -q -q -y --autoremove git wget ca-certificates gnupg composer
RUN ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite
RUN echo '30 7    * * *   www-data php /var/www/bin/catalog_update.inc' >> /etc/crontab

VOLUME ["/etc/mysql", "/var/lib/mysql", "/media", "/var/www/config", "/var/www/themes"]
EXPOSE 80

CMD ["/run.sh"]
