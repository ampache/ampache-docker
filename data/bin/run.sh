#!/bin/bash

if [[ ! -d /var/lib/mysql/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysql_install_db --auth-root-authentication-method=normal --user=mysql
    echo "=> Done!"
    create_mysql_admin_user.sh
else
    echo "=> Using an existing volume of MySQL"
fi

# Copy Ampache config .dist files
cp -p /var/tmp/*.dist /var/www/config/

# INSTALL
CONFIG_FILE="/var/www/config/ampache.cfg.php"

# Check for existing installation
if [ ! -f "$CONFIG_FILE" ]; then
    echo "=> Missing Ampache config file: $CONFIG_FILE"
    echo "=> Checking install variables ..."
    install.sh
else
    echo "=> Ampache config file found: $CONFIG_FILE"
fi

# Install the web client (the install script works out what it needs to download or build)
CLIENT_SCRIPT="/var/tmp/client/${CLIENT_INSTALL}"

if [ -n "$CLIENT_INSTALL" ] && [ -f "$CLIENT_SCRIPT" ]; then
    echo "=> Checking Ampache client install: $CLIENT_INSTALL"
    if [ ! -x "$CLIENT_SCRIPT" ]; then
        CLIENT_SCRIPT="bash $CLIENT_SCRIPT"
    fi
    if ! $CLIENT_SCRIPT; then
        echo "=> WARNING: Ampache client install failed: $CLIENT_INSTALL"
    fi
elif [ -n "$CLIENT_INSTALL" ]; then
    echo "=> Ampache client install script not found: $CLIENT_SCRIPT"
fi
# Set a default log file if LOG_FILE is not set
LOG_FILE=${LOG_FILE:-/var/log/ampache/ampache.log}

# Tail the log file if it exists
if [ -f "$LOG_FILE" ]; then
    echo "=> Tailing log file: $LOG_FILE"
    tail -F "$LOG_FILE" &
else
    echo "=> Log file not found: $LOG_FILE (will not tail)"
fi

# Start Supervisor to manage all the processes
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
