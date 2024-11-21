#!/bin/sh

if [ -f /var/run/apache2/apache2.pid ]; then
    rm -f /var/run/apache2/apache2.pid
fi

exec apachectl -DFOREGROUND
