#!/bin/sh

set -e

# Set custom group id (if set)
if [ -n "$GID" ]; then
    groupmod -o -g "$GID" www-data
fi

# Set custom user id (if set)
if [ -n "$UID" ]; then
    usermod -o -u "$UID" www-data
fi

# Drop root and run everything (apache, cron) as www-data, so the
# container runs rootless. This also avoids permission denied errors if the
# data volumes are mounted/owned by root.
if [ "$(id -u)" = '0' ]; then
    chown -R www-data:www-data /var/www/config /var/log/ampache /var/log/apache2 /var/log/supervisor /var/run/apache2
    exec gosu www-data "$@"
else
    exec "$@"
fi
