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

# Start Supervisor to manage all the processes
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
