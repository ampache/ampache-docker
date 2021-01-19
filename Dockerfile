FROM debian:stable
LABEL maintainer="lachlan-00"

ENV DEBIAN_FRONTEND=noninteractive
ARG VERSION=4.2.6

RUN     apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends \
          software-properties-common \
    &&  apt-add-repository contrib \
    &&  apt-add-repository non-free \
    &&  apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends libdvd-pkg \
    &&  dpkg-reconfigure libdvd-pkg \
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
          php \
          php-curl \
          php-gd \
          php-json \
          php-mysql \
          php-xml \
          pwgen \
          supervisor \
          vorbis-tools \
          zip \
          unzip \
    &&  rm -rf /var/www/* /etc/apache2/sites-enabled/* /var/lib/apt/lists/* \
    &&  wget -q -O /tmp/master.zip https://github.com/ampache/ampache/releases/download/${VERSION}/ampache-${VERSION}_all.zip \
    &&  unzip /tmp/master.zip -d /var/www/ \
    &&  mv /var/www/rest/.htac* /var/www/rest/.htaccess \
    &&  mv /var/www/play/.htac* /var/www/play/.htaccess \
    &&  mv /var/www/channel/.htac* /var/www/channel/.htaccess \
    &&  rm -rf /var/www/.git* /var/www/.php_cs /var/www/.sc /var/www/.scrutinizer.yml \
          /var/www/.tgitconfig /var/www/.travis.yml /var/www/.tx /var/www/*.md \
    &&  chown -R www-data:www-data /var/www \
    &&  chmod -R 775 /var/www \
    &&  ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/ \
    &&  a2enmod rewrite \
    &&  rm -rf /var/cache/* /tmp/* /var/tmp/* /root/.cache /var/www/docs \
    &&  echo '30 7 * * *   /usr/bin/php /var/www/bin/catalog_update.inc' | crontab -u www-data - \
    &&  apt-get -qq purge \
          libdvd-pkg \
          lsb-release \
          python3 \
          python3-minimal \
          software-properties-common \
    &&  apt-get -qq autoremove

VOLUME ["/media", "/var/www/config", "/var/www/themes"]
EXPOSE 80

COPY run.sh inotifywatch.sh cron.sh apache2.sh /usr/local/bin/
COPY data/sites-enabled/001-ampache.conf /etc/apache2/sites-available/
COPY data/config/ampache.cfg.* /var/temp/
RUN  chown www-data:www-data /var/temp/ampache.cfg.*
COPY docker-entrypoint.sh /usr/local/bin
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run.sh"]
