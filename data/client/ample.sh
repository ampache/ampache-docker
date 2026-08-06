#!/bin/bash

# Install the Ample client (https://github.com/mitchray/ample) into the Ampache web root.
#
# By default the latest published release is downloaded from GitHub and cached in the
# client volume. Set CLIENT_VERSION to pin a release tag, or CLIENT_ZIP to install from
# a local zip file instead (no network required).
#
# Variables:
#   CLIENT_VERSION  Release tag to install, or "latest" (Default: latest)
#   CLIENT_ZIP      Local zip to install instead of downloading
#   CLIENT_FORCE    If 1, reinstall even when Ample is already installed
#   AMPACHE_URL     Written into config/ample.json as the ampacheURL

set -e

REPO="mitchray/ample"
PUBLIC_DIR="/var/www/public"
CLIENT_DIR="/var/tmp/client"
CACHE_DIR="${CLIENT_DIR}/.cache"
CONFIG_FILE="${PUBLIC_DIR}/config/ample.json"

# Check for an existing installation
if [ -f "$CONFIG_FILE" ] && [ "${CLIENT_FORCE:-0}" != "1" ]; then
    echo "=> Ample is already installed: $CONFIG_FILE"
    exit 0
fi

mkdir -p "$CACHE_DIR"

# Work out which zip we are installing from
if [ -n "$CLIENT_ZIP" ]; then
    if [ -f "$CLIENT_ZIP" ]; then
        ZIP_FILE="$CLIENT_ZIP"
    elif [ -f "${CLIENT_DIR}/${CLIENT_ZIP}" ]; then
        ZIP_FILE="${CLIENT_DIR}/${CLIENT_ZIP}"
    else
        echo "=> ERROR: CLIENT_ZIP is set but the file was not found: $CLIENT_ZIP"
        exit 1
    fi
    echo "=> Installing Ample from a local zip: $ZIP_FILE"
else
    CLIENT_VERSION="${CLIENT_VERSION:-latest}"
    if [ "$CLIENT_VERSION" = "latest" ]; then
        echo "=> Looking up the latest Ample release"
        DOWNLOAD_URL=$(wget -q -O- "https://api.github.com/repos/${REPO}/releases/latest" \
            | grep -o '"browser_download_url": *"[^"]*\.zip"' \
            | head -1 \
            | cut -d'"' -f4)
    else
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${CLIENT_VERSION}/ample_${CLIENT_VERSION}.zip"
    fi

    if [ -z "$DOWNLOAD_URL" ]; then
        echo "=> ERROR: Unable to find an Ample release to download"
        exit 1
    fi

    ZIP_FILE="${CACHE_DIR}/$(basename "$DOWNLOAD_URL")"
    if [ -f "$ZIP_FILE" ]; then
        echo "=> Using the cached Ample download: $ZIP_FILE"
    else
        echo "=> Downloading Ample: $DOWNLOAD_URL"
        wget -q -O "${ZIP_FILE}.part" "$DOWNLOAD_URL"
        mv "${ZIP_FILE}.part" "$ZIP_FILE"
    fi
fi

# Extract to a temporary folder
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"

# Releases wrap everything in an ample/ folder, custom zips may not
SRC_DIR="$TMP_DIR"
if [ -d "${TMP_DIR}/ample" ]; then
    SRC_DIR="${TMP_DIR}/ample"
fi

# Copy to the Ampache folder
echo "=> Installing Ample into ${PUBLIC_DIR}"
cp -rf "${SRC_DIR}/." "${PUBLIC_DIR}/"

# Copy config file (a forced install picks up any AMPACHE_URL change)
if [ ! -f "$CONFIG_FILE" ] || [ "${CLIENT_FORCE:-0}" = "1" ]; then
    cp "${PUBLIC_DIR}/config/ample.json.dist" "$CONFIG_FILE"
fi

# sed in your ampache URL
sed -i "s|\"ampacheURL\": \"\"|\"ampacheURL\": \"${AMPACHE_URL}\"|g" "$CONFIG_FILE"

chown -R www-data:www-data "$PUBLIC_DIR"

echo "=> Ample install complete"
