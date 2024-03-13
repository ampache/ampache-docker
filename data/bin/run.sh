#!/bin/bash

mkdir /tmp/mysql /tmp/apache2
chmod 750 /tmp/mysql /tmp/apache2
if [[ ! -d /var/lib/mysql/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    if [ "$(id -u)" = '0' ]; then
        user=www-data
    else
        user=$(id -u)
    fi
    mysql_install_db --auth-root-authentication-method=normal --user $user
    echo "=> Done!"
    create_mysql_admin_user.sh
else
    echo "=> Using an existing volume of MySQL"
fi

# Copy Ampache config .dist files
cp /var/tmp/*.dist /var/www/config/

# Start Supervisor to manage all the processes
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
