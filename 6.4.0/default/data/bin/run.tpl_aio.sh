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

# Start Supervisor to manage all the processes
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
