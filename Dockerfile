FROM debian:stable
LABEL maintainer="lachlan-00"

ENV DEBIAN_FRONTEND=noninteractive
ENV DISABLE_INOTIFYWAIT_CLEAN 0
ARG VERSION=7.0.0

RUN     sh -c 'echo "Types: deb\n# http://snapshot.debian.org/archive/debian/20230612T000000Z\nURIs: http://deb.debian.org/debian\nSuites: stable stable-updates\nComponents: main contrib non-free\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n\nTypes: deb\n# http://snapshot.debian.org/archive/debian-security/20230612T000000Z\nURIs: http://deb.debian.org/debian-security\nSuites: stable-security\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n" > /etc/apt/sources.list.d/debian.sources' \
    &&  apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends wget lsb-release ca-certificates curl software-properties-common libdvd-pkg \
    &&  curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \
    &&  sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php2.list' \
    &&  apt-get update \
    &&  apt-get -q -q -y install --no-install-recommends \
          apache2 \
          beets \
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
          locales \
          logrotate \
          npm \
          php8.2 \
          php8.2-curl \
          php8.2-gd \
          php8.2-intl \
          php8.2-ldap \
          php8.2-mysql \
          php8.2-xml \
          php8.2-zip \
          pwgen \
          supervisor \
          vorbis-tools \
          zip \
          unzip \
          git \
    &&  rm -rf /var/www /etc/apache2/sites-enabled/* /var/lib/apt/lists/* \
    &&  mkdir -p /var/log/ampache \
    &&  chown -R www-data:www-data /var/log/ampache \
    &&  ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/ \
    &&  a2enmod rewrite \
    &&  wget -q -O /tmp/develop.zip https://github.com/ampache/ampache/archive/refs/heads/develop.zip \
    &&  unzip /tmp/develop.zip -d /tmp/ \
    &&  mv /tmp/ampache-develop/ /var/www/ \
    &&  cp -f /var/www/public/rest/.htaccess.dist /var/www/public/rest/.htaccess \
    &&  cp -f /var/www/public/play/.htaccess.dist /var/www/public/play/.htaccess \
    &&  cd /var/www \
    &&  wget -q -O ./composer https://getcomposer.org/download/latest-stable/composer.phar \
    &&  chmod +x ./composer \
    &&  ./composer install --prefer-dist --no-interaction \
    &&  ./composer clear-cache \
    &&  npm install \
    &&  npm run build \
    &&  npm cache clean --force \
    &&  rm ./composer \
    &&  cp -f /var/www/config/ampache.cfg.php.dist /var/tmp/ \
    &&  rm -f /var/www/.php*cs* /var/www/.sc /var/www/.scrutinizer.yml \
          /var/www/.tgitconfig /var/www/.travis.yml /var/www/*.md \
    &&  find /var/www -type d -name ".git*" -print0 | xargs -0 rm -rf {} \
    &&  chown -R www-data:www-data /var/www \
    &&  chmod -R 775 /var/www \
    &&  rm -rf /var/cache/* /tmp/* /var/tmp/develop.zip /root/.cache /var/www/docs /var/www/.tx \
    &&  echo '30 * * * *   /usr/local/bin/ampache_cron.sh' | crontab -u www-data - \
    &&  sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    &&  locale-gen \
    &&  apt-get -q -q purge \
          build-essential \
          debhelper-compat \
          libdvd-pkg \
          lsb-release \
          software-properties-common \
          git \
          npm \
          unzip \
          wget \
    &&  apt-get -q -q autoremove

VOLUME ["/var/www/config"]
EXPOSE 80

COPY data/bin/run.sh data/bin/inotifywait.sh data/bin/cron.sh data/bin/apache2.sh data/bin/ampache_cron.sh data/bin/docker-entrypoint.sh /usr/local/bin/
COPY data/sites-enabled/001-ampache.conf /etc/apache2/sites-available/
COPY data/apache2/php.ini /etc/php/8.2/apache2/
COPY data/logrotate.d/* /etc/logrotate.d/
COPY data/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN  chown -R www-data:www-data /var/tmp/ampache.cfg.php.dist /var/www/config \
    &&  chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run.sh"]
