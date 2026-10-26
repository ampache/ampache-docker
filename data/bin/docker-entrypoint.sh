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

WWW_UID=$(id -u www-data)
WWW_GID=$(id -g www-data)

# Re-set permission to the mysql folder if current user/groups do not match.
# mysqld runs as www-data (below) so the whole container can run rootless
# using the UID/GID above. The ID's may also change between OS upgrades.
if [ -d /var/lib/mysql ]; then
    DIR_UID=$(stat -c %u /var/lib/mysql)
    DIR_GID=$(stat -c %g /var/lib/mysql)

    if [ "$WWW_UID" -ne "$DIR_UID" ] || [ "$WWW_GID" -ne "$DIR_GID" ]; then
        echo "=> Fixing ownership of /var/lib/mysql (expected ${WWW_UID}:${WWW_GID}, found ${DIR_UID}:${DIR_GID})"
        chown -R "$WWW_UID":"$WWW_GID" /var/lib/mysql
    fi
fi

# Drop root and run everything (apache, mysql, cron) as www-data, so the
# container runs rootless. This also avoids permission denied errors if the
# data volumes are mounted/owned by root.
if [ "$(id -u)" = '0' ]; then
    chown -R www-data:www-data /var/www/config /var/log/ampache /var/log/apache2 /var/log/supervisor /var/run/apache2 /var/run/mysqld
    exec gosu www-data "$@"
else
    exec "$@"
fi
