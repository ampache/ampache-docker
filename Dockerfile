# Re-set permission to the `www-data` user if current user is root
# This avoids permission denied if the data volume is mounted by root
FROM debian:stable
LABEL maintainer="lachlan-00"

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_PASS=**Random**
ENV DISABLE_INOTIFYWAIT_CLEAN=0
ARG VERSION=7.8.0

RUN     sh -c 'echo "Types: deb\n# http://snapshot.debian.org/archive/debian/20230612T000000Z\nURIs: http://deb.debian.org/debian\nSuites: stable stable-updates\nComponents: main contrib non-free\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n\nTypes: deb\n# http://snapshot.debian.org/archive/debian-security/20230612T000000Z\nURIs: http://deb.debian.org/debian-security\nSuites: stable-security\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n" > /etc/apt/sources.list.d/debian.sources' \
    &&  apt-get -q -q update \
    &&  apt-get -q -q -y install --no-install-recommends wget lsb-release ca-certificates libdvd-pkg extrepo \
    &&  extrepo enable sury \
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
          mariadb-server \
          npm \
          php8.4 \
          php8.4-curl \
          php8.4-gd \
          php8.4-intl \
          php8.4-ldap \
          php8.4-mysql \
          php8.4-xml \
          php8.4-zip \
          pwgen \
          supervisor \
          vorbis-tools \
          zip \
          unzip \
          git \
    &&  rm -rf /var/lib/mysql/* /var/www /etc/apache2/sites-enabled/* /var/lib/apt/lists/* \
    &&  mkdir -p /var/run/mysqld \
    &&  chown -R mysql /var/run/mysqld \
    &&  mkdir -p /var/log/ampache \
    &&  chown -R www-data:www-data /var/log/ampache \
    &&  ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/ \
    &&  a2enmod rewrite \
    &&  wget -q -O /tmp/develop.zip https://github.com/ampache/ampache/archive/refs/heads/develop.zip \
    &&  unzip /tmp/develop.zip -d /tmp/ \
    &&  mv /tmp/ampache-develop/ /var/www/ \
    &&  cp -f /var/www/public/rest/.htaccess.dist /var/www/public/rest/.htaccess \
    &&  cp -f /var/www/public/play/.htaccess.dist /var/www/public/play/.htaccess \
    &&  cp -f /var/www/public/.htaccess.dist /var/www/public/.htaccess \
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
    &&  rm -rf /var/cache/* /tmp/* /var/tmp/develop.zip /root/.cache /var/www/docs /var/www/.tx /var/log/dpkg.log \
    &&  echo '30 * * * *   /usr/local/bin/ampache_cron.sh' | crontab -u www-data - \
    &&  sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    &&  locale-gen \
    &&  apt-get -qq purge \
          build-essential \
          debhelper-compat \
          extrepo \
          libdvd-pkg \
          lsb-release \
          npm \
          unzip \
          wget \
    &&  apt-get -qq autoremove

VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/www/config"]
EXPOSE 80

COPY data/bin/run.sh data/bin/inotifywait.sh data/bin/cron.sh data/bin/apache2.sh data/bin/mysql.sh data/bin/create_mysql_admin_user.sh data/bin/install.sh data/bin/ampache_cron.sh data/bin/docker-entrypoint.sh /usr/local/bin/
COPY data/sites-enabled/001-ampache.conf /etc/apache2/sites-available/
COPY data/apache2/php.ini /etc/php/8.4/apache2/
COPY data/logrotate.d/* /etc/logrotate.d/
COPY data/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN  chown -R www-data:www-data /var/tmp/ampache.cfg.php.dist /var/www/config \
    &&  chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run.sh"]
