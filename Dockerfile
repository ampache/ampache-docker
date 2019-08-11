FROM ubuntu:18.04
MAINTAINER Afterster

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_PASS **Random**

ADD create_mysql_admin_user.sh run.sh /
ADD ampache.cfg.php.dist /var/temp/ampache.cfg.php.dist
ADD 001-ampache.conf /etc/apache2/sites-available/

RUN chmod 0755 /*.sh
RUN apt-get -q -q update
RUN apt-get -q -q -y install --no-install-recommends wget gnupg ca-certificates
RUN echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.list
RUN wget -qO - https://download.videolan.org/pub/debian/videolan-apt.asc | apt-key add -
RUN apt-get -q -q update
RUN apt-get -q -q -y upgrade --no-install-recommends
RUN apt-get -q -q -y install --no-install-recommends inotify-tools mysql-server apache2 php php-json php-curl php-mysql composer libev-libevent-dev pwgen lame libvorbis-dev vorbis-tools flac libmp3lame-dev libfaac-dev libtheora-dev libvpx-dev libavcodec-extra ffmpeg git cron
RUN mkdir -p /var/run/mysqld \
    && chown -R mysql /var/run/mysqld \
RUN rm -rf /var/lib/mysql/* /var/www/* /etc/apache2/sites-enabled/* && \
    wget -qO - https://github.com/ampache/ampache/archive/master.tar.gz \
        | tar -C /var/www -xzf - ampache-master --strip=1 && \
    chown -R www-data /var/www && \
    su -s /bin/sh -c 'cd /var/www && composer install --prefer-source --no-interaction' www-data
RUN apt-get purge -q -q -y --autoremove git wget ca-certificates gnupg composer
RUN ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite
RUN rm -rf /var/cache/* /tmp/* /var/tmp/* /root/.cache /var/www/.composer \
    && find /var/www -type d -name '.git' -print0 | xargs -0 -L1 -- rm -rf

RUN echo '30 7    * * *   www-data php /var/www/bin/catalog_update.inc' >> /etc/crontab

VOLUME ["/etc/mysql", "/var/lib/mysql", "/media", "/var/www/config", "/var/www/themes"]
EXPOSE 80

CMD ["/run.sh"]
