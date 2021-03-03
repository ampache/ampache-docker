FROM composer:1.10.8 AS Builder

ADD https://github.com/ampache/ampache/archive/develop.tar.gz /tmp
RUN     tar -xzf /tmp/develop.tar.gz --strip=1 -C . \
    &&  apk add --no-cache php-intl icu-dev \
    &&  docker-php-ext-install intl \
    &&  composer install --prefer-source --no-interaction \
    &&  rm -rf .git* .php_cs .sc .scrutinizer.yml .tgitconfig .travis.yml .tx *.md \
    &&  mv ./public/rest/.htac* ./public/rest/.htaccess \
    &&  mv ./public/play/.htac* ./public/play/.htaccess \
    &&  mv ./public/channel/.htac* ./public/channel/.htaccess \
    &&  chmod -R 775 .

FROM debian:stable
LABEL maintainer="lachlan-00"

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_PASS **Random**

RUN     apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends \
          software-properties-common \
          wget \
    &&  apt-add-repository contrib \
    &&  apt-add-repository non-free \
    &&  apt-get update \
    &&  apt-get -q -q -y install --no-install-recommends libdvd-pkg \
    &&  dpkg-reconfigure libdvd-pkg \
    &&  apt-get -qq install apt-transport-https lsb-release ca-certificates curl \
    &&  wget -q -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    &&  sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
    &&  apt-get update \
    &&  apt-get -qq install --no-install-recommends \
          apache2 \
          cron \
          ffmpeg \
          flac \
          gosu \
          inotify-tools \
          lame \
          libavcodec-extra \
          libev-libevent-dev \
          libfaac-dev \
          libmp3lame-dev \
          libtheora-dev \
          libvorbis-dev \
          libvpx-dev \
          mariadb-server \
          php7.4 \
          php7.4-curl \
          php7.4-gd \
          php7.4-intl \
          php7.4-json \
          php7.4-mysql \
          php7.4-xml \
          supervisor \
          vorbis-tools \
          zip \
    &&  rm -rf /var/lib/mysql/* /var/www/* /etc/apache2/sites-enabled/* /var/lib/apt/lists/* \
    &&  mkdir -p /var/run/mysqld \
    &&  chown -R mysql /var/run/mysqld \
    &&  ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/ \
    &&  a2enmod rewrite \
    &&  rm -rf /var/cache/* /tmp/* /var/tmp/* /root/.cache /var/www/docs \
    &&  echo '30 7 * * *   /usr/bin/php /var/www/bin/catalog_update.inc' | crontab -u www-data -

COPY --from=Builder --chown=www-data:www-data /app /var/www
RUN     apt-get -qq purge \
          libdvd-pkg \
          lsb-release \
          python3 \
          python3-minimal \
          software-properties-common \
    &&  apt-get -qq autoremove

VOLUME ["/etc/mysql", "/var/lib/mysql", "/media", "/var/www/config", "/var/www/themes"]
EXPOSE 80

COPY run.sh inotifywatch.sh cron.sh apache2.sh mysql.sh create_mysql_admin_user.sh /usr/local/bin/
COPY data/sites-enabled/001-ampache.conf /etc/apache2/sites-available/
COPY data/config/ampache.cfg.* /var/temp/
RUN  chown www-data:www-data /var/temp/ampache.cfg.*
COPY docker-entrypoint.sh /usr/local/bin
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run.sh"]
