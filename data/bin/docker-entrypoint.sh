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

# Re-set permission to the mysql folder if current user/groups do not match
# The ID's may change between OS upgrades. (Bookworm => Trixie had this issue)
if id mysql >/dev/null 2>&1; then
    MYSQL_UID=$(id -u mysql)
    MYSQL_GID=$(id -g mysql)
    DIR_UID=$(stat -c %u /var/lib/mysql)
    DIR_GID=$(stat -c %g /var/lib/mysql)

    if [ "$MYSQL_UID" -ne "$DIR_UID" ] || [ "$MYSQL_GID" -ne "$DIR_GID" ]; then
        echo "=> Fixing ownership of /var/lib/mysql (expected ${MYSQL_UID}:${MYSQL_GID}, found ${DIR_UID}:${DIR_GID})"
        chown -R mysql:mysql /var/lib/mysql
    fi
fi

# Re-set permission to the `www-data` user if current user is root
# This avoids permission denied if the data volume is mounted by root
if [ "$1" = '/usr/local/bin/run.sh' ] && [ "$(id -u)" = '0' ]; then
    chown -R www-data:www-data /var/www/config /var/log/ampache
    exec gosu www-data "$@"
else
  exec "$@"
fi
