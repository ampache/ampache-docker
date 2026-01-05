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
        echo "Fixing ownership of /var/lib/mysql (expected ${MYSQL_UID}:${MYSQL_GID}, found ${DIR_UID}:${DIR_GID})"
        chown -R mysql:mysql /var/lib/mysql
    fi
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
CONFIG_FILE="/var/www/config/ampache.cfg.php"

# Check for existing installation
if [ -f "$CONFIG_FILE" ]; then
    echo "Ampache is installed"
else
    if [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ] && [ -n "$DB_HOST" ]; then
        # php /var/www/html/bin/installer install
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

        echo "Installing Ampache database"
        $INSTALL_COMMAND
    fi
    if [ -n "$AMPACHE_ADMIN_USER" ] && [ -n "$AMPACHE_ADMIN_EMAIL" ] ; then
        if [ "$MYSQL_PASS" = "**Random**" ]; then
            AMPACHE_ADMIN_PASSWORD=$(pwgen -s 14 1)
        fi

        echo "Creating Ampache admin user"
        php /var/www/bin/cli admin:addUser "$AMPACHE_ADMIN_USER" -p "$AMPACHE_ADMIN_PASSWORD" -e "$AMPACHE_ADMIN_EMAIL" -l 100
    fi
fi