#!/bin/sh

set -e

if [ -n "$GID" ]; then
    groupmod -o -g "$GID" www-data
fi

if [ -n "$UID" ]; then
    usermod -o -u "$UID" www-data
fi

# Re-set permission to the `www-data` user if current user is root
# This avoids permission denied if the data volume is mounted by root
if [ "$1" = '/usr/local/bin/run.sh' ] && [ "$(id -u)" = '0' ]; then
    chown -R www-data:www-data /var/www/config /var/log/ampache
    exec gosu www-data "$@"
else
  exec "$@"
fi
