FROM debian:stable
LABEL maintainer="lachlan-00"

ENV DEBIAN_FRONTEND=noninteractive
ARG VERSION=5.1.0

RUN     apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends \
          software-properties-common \
          wget \
    &&  apt-add-repository contrib \
    &&  apt-add-repository non-free \
    &&  apt-get -q -q update \
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
          php7.4 \
          php7.4-curl \
          php7.4-gd \
          php7.4-intl \
          php7.4-json \
          php7.4-ldap \
          php7.4-mysql \
          php7.4-xml \
          php7.4-zip \
          pwgen \
          supervisor \
          vorbis-tools \
          zip \
          unzip \
    &&  rm -rf /var/www/* /etc/apache2/sites-enabled/* /var/lib/apt/lists/* \
    &&  mkdir -p /var/log/ampache \
    &&  chown -R www-data:www-data /var/log/ampache \
    &&  ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/ \
    &&  a2enmod rewrite \
    &&  wget -q -O /tmp/master.zip https://github.com/ampache/ampache/releases/download/${VERSION}/ampache-${VERSION}_all.zip \
    &&  unzip /tmp/master.zip -d /var/www/ \
    &&  mv /var/www/public/rest/.htac* /var/www/public/rest/.htaccess \
    &&  mv /var/www/public/play/.htac* /var/www/public/play/.htaccess \
    &&  mv /var/www/public/channel/.htac* /var/www/public/channel/.htaccess \
    &&  rm -f /var/www/.php*cs* /var/www/.sc /var/www/.scrutinizer.yml \
          /var/www/.tgitconfig /var/www/.travis.yml /var/www/*.md \
    &&  find /var/www -type d -name ".git*" -print0 | xargs -0 rm -rf {} \
    &&  chown -R www-data:www-data /var/www \
    &&  chmod -R 775 /var/www \
    &&  rm -rf /var/cache/* /tmp/* /var/tmp/* /root/.cache /var/www/docs /var/www/.tx \
    &&  echo '30 * * * *   /usr/local/bin/ampache_cron.sh' | crontab -u www-data - \
    &&  apt-get -qq purge \
          libdvd-pkg \
          lsb-release \
          software-properties-common \
          unzip \
          wget \
    &&  apt-get -qq autoremove

VOLUME ["/media", "/var/www/config", "/var/www/themes"]
EXPOSE 80

COPY run.sh inotifywatch.sh cron.sh apache2.sh ampache_cron.sh docker-entrypoint.sh /usr/local/bin/
COPY data/sites-enabled/001-ampache.conf /etc/apache2/sites-available/
COPY data/config/ampache.cfg.* /var/tmp/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN  chown www-data:www-data /var/tmp/ampache.cfg.* \
    &&  chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run.sh"]
