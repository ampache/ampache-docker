#!/bin/sh

# INSTALL
CONFIG_FILE="/var/www/public/config/ample.json"

if [ ! -f "$CLIENT_ZIP" ]; then
    CLIENT_ZIP="/var/tmp/client/$CLIENT_ZIP"
fi

# Check for existing installation
if [ -f "$CLIENT_ZIP" ] && [ ! -f "$CONFIG_FILE" ]; then
  # Extract Ample to /tmp
  unzip /var/tmp/client/$CLIENT_ZIP -d /tmp/
  # Copy to the Ampache folder
  cp -vrf /tmp/ample/* /var/www/public/
  # Copy config file
  cp /var/www/public/config/ample.json.dist /var/www/public/config/ample.json
  # sed in your ampache URL
  sed -i "s/\"ampacheURL\": \"\"/\"ampacheURL\": \"$AMPACHE_URL\"/g"  /var/www/public/config/ample.json
fi
