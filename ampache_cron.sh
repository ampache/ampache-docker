#!/bin/bash

DOW=$(date +%u)
HOUR=$(date +"%H")

# catalog clean / add / gather art
if [[ $HOUR = 22 ]]; then
  /usr/bin/php /var/www/bin/cli run:updateCatalog -cag
fi
# optimize DB on sunday
if [[ $HOUR = 01 ]] && [[ $DOW = 6 ]]; then
  /usr/bin/php /var/www/bin/cli run:updateCatalog -o
fi

# will only run if enabled
/usr/bin/php /var/www/bin/cli run:cronProcess
