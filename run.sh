#!/bin/bash

VOLUME_HOME="/var/lib/mysql"

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysql_install_db > /dev/null 2>&1
    echo "=> Done!"
    /create_mysql_admin_user.sh
else
    echo "=> Using an existing volume of MySQL"
fi

if [[ ! -f /var/www/config/ampache.cfg.php ]]; then
    mv /var/temp/ampache.cfg.php.dist /var/www/config/ampache.cfg.php.dist
fi


# Start apache in the background
service apache2 start

# Start cron in the background
cron

# Start a process to watch for changes in the library with inotify
(
while true; do
    inotifywatch /media
    php /var/www/bin/catalog_update.inc -a
    sleep 30
done
) &

# run this in the foreground so Docker won't exit
exec mysqld_safe
