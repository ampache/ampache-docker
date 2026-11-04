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

# Fix up permissions on the volumes Apache writes to as www-data (via its
# own config, not by dropping this process's privileges: mariadb-install-db,
# cron and supervisord all still need root here). This is also what makes a
# custom UID/GID actually take effect, including for a host user who only
# shares the GID (not the UID), e.g. to edit the config file from a desktop.
if [ "$(id -u)" = '0' ]; then
    WWW_UID=$(id -u www-data)
    WWW_GID=$(id -g www-data)
    chown -R "$WWW_UID":"$WWW_GID" /var/www/config /var/log/ampache
    chmod -R g+rwX /var/www/config /var/log/ampache
fi

exec "$@"
