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
