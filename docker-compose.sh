#!/bin/sh

# make dirs if missing
if [ ! -d ./data ]; then
  mkdir ./data
fi
if [ ! -d ./data/config ]; then
  mkdir ./data/config
fi
if [ ! -d ./data/log ]; then
  mkdir ./data/log
fi
if [ ! -d ./data/media ]; then
  mkdir ./data/media
fi

# add missing files
if [ ! -f ./data/config/ampache.cfg.php.dist ]; then
  wget -q -O ./data/config/ampache.cfg.php.dist https://raw.githubusercontent.com/ampache/ampache-docker/develop/data/config/ampache.cfg.php.dist
fi
if [ ! -f ./data/sites-enabled/001-ampache.conf ]; then
  wget -q -O ./data/config/ampache.cfg.php.dist https://raw.githubusercontent.com/ampache/ampache-docker/develop/data/sites-enabled/001-ampache.conf
fi

# set permissions
chown 33:33 ./data/config -R
chown 33:33 ./data/log -R
