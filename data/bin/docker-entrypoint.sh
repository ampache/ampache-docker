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

# Fix up permissions on the volumes Apache writes to as www-data (via its
# own config, not by dropping this process's privileges: cron and
# supervisord still need root here). This is also what makes a custom
# UID/GID actually take effect, including for a host user who only shares
# the GID (not the UID), e.g. to edit the config file from a desktop.
if [ "$(id -u)" = '0' ]; then
    WWW_UID=$(id -u www-data)
    WWW_GID=$(id -g www-data)
    chown -R "$WWW_UID":"$WWW_GID" /var/www/config /var/log/ampache
    chmod -R g+rwX /var/www/config /var/log/ampache
fi

exec "$@"
