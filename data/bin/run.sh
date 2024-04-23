#!/bin/bash

# Copy Ampache config .dist files
cp -p /var/tmp/*.dist /var/www/config/

# Start Supervisor to manage all the processes
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
