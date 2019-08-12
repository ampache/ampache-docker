FROM ubuntu:18.04
MAINTAINER Afterster

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_PASS **Random**

ADD create_mysql_admin_user.sh run.sh /
ADD 001-ampache.conf /etc/apache2/sites-available/
COPY ampache.cfg.* /var/temp/

RUN     chmod 0755 /*.sh \
    &&  chmod +x /*.sh \
    &&  apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends wget gnupg ca-certificates \
    &&  echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.list \
    &&  wget -qO - https://download.videolan.org/pub/debian/videolan-apt.asc | apt-key add - \
    &&  apt-get -q -q update \
    &&  apt-get -q -q -y upgrade --no-install-recommends \
    &&  apt-get -q -q -y install --no-install-recommends \
          inotify-tools mysql-server apache2 php php-json \
          php-curl php-mysql php-gd php-xml composer libev-libevent-dev \
          pwgen lame libvorbis-dev vorbis-tools flac \
          libmp3lame-dev libfaac-dev libtheora-dev libvpx-dev \
          libavcodec-extra ffmpeg git cron \
    &&  mkdir -p /var/run/mysqld \
    &&  chown -R mysql /var/run/mysqld \
    &&  rm -rf /var/lib/mysql/* /var/www/* /etc/apache2/sites-enabled/* \
    &&  wget -qO - https://github.com/ampache/ampache/archive/master.tar.gz \
          | tar -C /var/www -xzf - ampache-master --strip=1 \
    &&  chown -R www-data:www-data /var/www \
    &&  chmod -R 775 /var/www \
    &&  su -s /bin/sh -c 'cd /var/www && composer install --prefer-source --no-interaction' www-data \
    &&  apt-get purge -q -q -y --autoremove git wget ca-certificates gnupg composer \
    &&  ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/ \
    &&  a2enmod rewrite \
    &&  rm -rf /var/cache/* /tmp/* /var/tmp/* /root/.cache /var/www/.composer \
    &&  find /var/www -type d -name '.git' -print0 | xargs -0 -L1 -- rm -rf \
    &&  echo '30 7 * * *   /usr/bin/php /var/www/bin/catalog_update.inc' | crontab -u www-data -

VOLUME ["/etc/mysql", "/var/lib/mysql", "/media", "/var/www/config", "/var/www/themes"]
EXPOSE 80

CMD ["/run.sh"]
