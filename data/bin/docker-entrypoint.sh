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

# Set a default log file if LOG_FILE is not set
LOG_FILE=${LOG_FILE:-/var/log/ampache/ampache.log}

# Tail the log file if it exists
if [ -f "$LOG_FILE" ]; then
    echo "Tailing log file: $LOG_FILE"
    tail -F "$LOG_FILE" &
else
    echo "Log file not found: $LOG_FILE (will not tail)"
fi

# Re-set permission to the `www-data` user if current user is root
# This avoids permission denied if the data volume is mounted by root
if [ "$1" = '/usr/local/bin/run.sh' ] && [ "$(id -u)" = '0' ]; then
    chown -R www-data:www-data /var/www/config /var/log/ampache
    exec gosu www-data "$@"
else
  exec "$@"
fi

# INSTALL
# php /var/www/html/bin/installer install
if [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ] && [ -n "$DB_HOST" ]; then
    INSTALL_COMMAND="php /var/www/bin/installer install --dbname $DB_NAME --dbuser $DB_USER --dbpassword $DB_PASSWORD --dbhost $DB_HOST"
    # Add --force flag only when FORCE_INSTALL=1
    if [ "${FORCE_INSTALL:-0}" = "1" ]; then
        INSTALL_COMMAND="$INSTALL_COMMAND --force"
    fi
    if [ -n "$DB_PORT" ]; then
        INSTALL_COMMAND="$INSTALL_COMMAND --dbport $DB_PORT"
    fi
    if [ -n "$AMPACHE_DB_USER" ] && [ -n "$AMPACHE_DB_PASSWORD" ]; then
        INSTALL_COMMAND="$INSTALL_COMMAND --ampachedbuser $AMPACHE_DB_USER --ampachedbpassword $AMPACHE_DB_PASSWORD"
    else
        INSTALL_COMMAND="$INSTALL_COMMAND --ampachedbuser $DB_USER --ampachedbpassword $DB_PASSWORD"
    fi

    $INSTALL_COMMAND
fi