#!/bin/bash

mysqld_safe &
sleep 5

RET=1
while [ $RET -ne 0 ]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

if [ "$MYSQL_PASS" = "**Random**" ]; then
    unset MYSQL_PASS
fi


# INSTALL
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

    echo "=> Installing Ampache database"
    $INSTALL_COMMAND
fi
if [ -n "$AMPACHE_ADMIN_USER" ] && [ -n "$AMPACHE_ADMIN_EMAIL" ] ; then
    if [ "$MYSQL_PASS" = "**Random**" ]; then
        AMPACHE_ADMIN_PASSWORD=$(pwgen -s 14 1)
    fi

    echo "=> Creating Ampache admin user"
    php /var/www/bin/cli admin:addUser "$AMPACHE_ADMIN_USER" -p "$AMPACHE_ADMIN_PASSWORD" -e "$AMPACHE_ADMIN_EMAIL" -l 100
fi

# shutdown MySQL to allow supervisor to take over
mysqladmin -uroot shutdown