#!/bin/bash

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

# Check for existing installation
if [ -f "/var/tmp/client/$CLIENT_ZIP" ] && [ -f "/var/tmp/client/$CLIENT_INSTALL" ]; then
    echo "=> Checking Ampache client install: $CLIENT_ZIP"
    /var/tmp/client/$CLIENT_INSTALL
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
