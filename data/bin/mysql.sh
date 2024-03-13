#!/bin/sh
if [ "$(id -u)" = '0' ]; then
    user=www-data
else
    user=$(id -u)
fi
exec mysqld_safe --user $user
