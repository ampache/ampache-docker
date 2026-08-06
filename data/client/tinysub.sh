#!/bin/bash

# Build and install the tinysub client (https://tangled.org/devins.page/tinysub) into the
# Ampache web root.
#
# tinysub is an OpenSubsonic client, so it talks to the Subsonic API at /rest and needs
# "subsonic_backend" enabled in your Ampache config.
#
# There are no published build artifacts, so the latest tagged source is cloned and built
# with npm. tinysub bakes its settings into the build, which means changing any TINYSUB_*
# variable below triggers a rebuild. Builds are cached in the client volume so recreating
# the container reuses the existing build instead of building again.
#
# Variables:
#   CLIENT_VERSION        Tag to build, or "latest" (Default: latest)
#   CLIENT_FORCE          If 1, rebuild and reinstall even when already installed
#   TINYSUB_SERVER        Prefilled server url (Fallback to AMPACHE_URL)
#   TINYSUB_SERVER_LOCK   If true, hide the server url input (Default: false)
#   TINYSUB_USERNAME      Prefilled username
#   TINYSUB_PASSWORD      Prefilled password
#   TINYSUB_NAME          Deployment name shown in settings
#   TINYSUB_BASE_URL      Base path of the build (Default: /)
#   TINYSUB_BUILD_TARGET  Browser build target
#   TINYSUB_DIST          Prebuilt dist folder or zip to install instead of building
#
# The username and password are embedded in the build and readable by anyone who can
# load the page. Only use them for demo accounts, never for a real user.

set -e

REPO="https://tangled.org/devins.page/tinysub"
PUBLIC_DIR="/var/www/public"
CLIENT_DIR="/var/tmp/client"
CACHE_DIR="${CLIENT_DIR}/.cache"
BUILD_CACHE="${CACHE_DIR}/tinysub"
STAMP_FILE="${PUBLIC_DIR}/config/tinysub.build"

TINYSUB_SERVER="${TINYSUB_SERVER:-$AMPACHE_URL}"
TINYSUB_SERVER_LOCK="${TINYSUB_SERVER_LOCK:-false}"
TINYSUB_BASE_URL="${TINYSUB_BASE_URL:-/}"

# Everything that gets baked into the build. A change here means a rebuild.
# These are exported for the build rather than written to a .env file, because vite reads
# prefixed variables straight from the environment and that avoids .env quoting rules
# mangling values containing $, " or #
export VITE_TINYSUB_BASE_URL="${TINYSUB_BASE_URL}"
export VITE_TINYSUB_BUILD_TARGET="${TINYSUB_BUILD_TARGET}"
export VITE_TINYSUB_NAME="${TINYSUB_NAME}"
export VITE_TINYSUB_SERVER="${TINYSUB_SERVER}"
export VITE_TINYSUB_SERVER_LOCK="${TINYSUB_SERVER_LOCK}"
export VITE_TINYSUB_USERNAME="${TINYSUB_USERNAME}"
export VITE_TINYSUB_PASSWORD="${TINYSUB_PASSWORD}"

SETTINGS_HASH=$(printf '%s\0' \
    "$VITE_TINYSUB_BASE_URL" \
    "$VITE_TINYSUB_BUILD_TARGET" \
    "$VITE_TINYSUB_NAME" \
    "$VITE_TINYSUB_SERVER" \
    "$VITE_TINYSUB_SERVER_LOCK" \
    "$VITE_TINYSUB_USERNAME" \
    "$VITE_TINYSUB_PASSWORD" | md5sum | cut -d' ' -f1)

mkdir -p "$BUILD_CACHE" "${PUBLIC_DIR}/config"

install_dist() {
    # $1: folder containing the built client
    echo "=> Installing tinysub into ${PUBLIC_DIR}"
    cp -rf "${1}/." "${PUBLIC_DIR}/"
    chown -R www-data:www-data "$PUBLIC_DIR"
}

# A prebuilt copy skips the build entirely (useful where building is slow or unwanted)
if [ -n "$TINYSUB_DIST" ]; then
    DIST_PATH="$TINYSUB_DIST"
    if [ ! -e "$DIST_PATH" ]; then
        DIST_PATH="${CLIENT_DIR}/${TINYSUB_DIST}"
    fi
    if [ -d "$DIST_PATH" ]; then
        echo "=> Installing tinysub from a prebuilt folder: $DIST_PATH"
        install_dist "$DIST_PATH"
    elif [ -f "$DIST_PATH" ]; then
        echo "=> Installing tinysub from a prebuilt zip: $DIST_PATH"
        TMP_DIR=$(mktemp -d)
        trap 'rm -rf "$TMP_DIR"' EXIT
        unzip -q -o "$DIST_PATH" -d "$TMP_DIR"
        if [ -d "${TMP_DIR}/dist" ]; then
            install_dist "${TMP_DIR}/dist"
        else
            install_dist "$TMP_DIR"
        fi
    else
        echo "=> ERROR: TINYSUB_DIST is set but was not found: $TINYSUB_DIST"
        exit 1
    fi
    echo "prebuilt-${SETTINGS_HASH}" > "$STAMP_FILE"
    echo "=> tinysub install complete"
    exit 0
fi

# Work out which tag to build
CLIENT_VERSION="${CLIENT_VERSION:-latest}"
if [ "$CLIENT_VERSION" = "latest" ]; then
    echo "=> Looking up the latest tinysub release"
    VERSION=$(git ls-remote --tags --refs --sort=-v:refname "$REPO" 'v*' 2>/dev/null \
        | head -1 \
        | sed 's#.*refs/tags/##')
else
    VERSION="$CLIENT_VERSION"
fi

# Without a version we can still reinstall a cached build (e.g. the network is down)
if [ -z "$VERSION" ]; then
    CACHED=$(ls -1dt "${BUILD_CACHE}"/*/dist 2>/dev/null | head -1)
    if [ -n "$CACHED" ]; then
        echo "=> WARNING: Unable to reach $REPO, using the last cached build"
        install_dist "$CACHED"
        basename "$(dirname "$CACHED")" > "$STAMP_FILE"
        echo "=> tinysub install complete"
        exit 0
    fi
    echo "=> ERROR: Unable to work out which tinysub version to build"
    exit 1
fi

BUILD_ID="${VERSION}-${SETTINGS_HASH}"
BUILD_DIR="${BUILD_CACHE}/${BUILD_ID}"

# Check for an existing installation
if [ -f "$STAMP_FILE" ] && [ "$(cat "$STAMP_FILE")" = "$BUILD_ID" ] && [ "${CLIENT_FORCE:-0}" != "1" ]; then
    echo "=> tinysub ${VERSION} is already installed"
    exit 0
fi

# Reuse a matching build from a previous container if we have one
if [ -d "${BUILD_DIR}/dist" ] && [ "${CLIENT_FORCE:-0}" != "1" ]; then
    echo "=> Using the cached tinysub ${VERSION} build"
    install_dist "${BUILD_DIR}/dist"
    echo "$BUILD_ID" > "$STAMP_FILE"
    echo "=> tinysub install complete"
    exit 0
fi

if ! command -v npm > /dev/null 2>&1; then
    echo "=> ERROR: npm is required to build tinysub (set TINYSUB_DIST to install a prebuilt copy)"
    exit 1
fi

# vite needs node ^20.19.0 || >=22.12.0
NODE_VERSION=$(node -v | tr -d 'v')
if [ "$(printf '%s\n' "20.19.0" "$NODE_VERSION" | sort -V | head -1)" != "20.19.0" ]; then
    echo "=> WARNING: node ${NODE_VERSION} is older than the 20.19.0 vite requires, the build may fail"
fi

if [ -n "$TINYSUB_PASSWORD" ]; then
    echo "=> WARNING: TINYSUB_PASSWORD is embedded in the build and readable by anyone who loads the page"
fi

SRC_DIR="${BUILD_CACHE}/src"
rm -rf "$SRC_DIR"

echo "=> Cloning tinysub ${VERSION}"
git clone --quiet --depth 1 --branch "$VERSION" "$REPO" "$SRC_DIR"

# Keep the npm cache in the client volume so later builds are quicker
export npm_config_cache="${CACHE_DIR}/npm"

echo "=> Building tinysub ${VERSION} (this takes a while on the first run)"
cd "$SRC_DIR"
npm ci --no-audit --no-fund || npm install --no-audit --no-fund
npm run build

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp -rf "${SRC_DIR}/dist" "${BUILD_DIR}/dist"

# node_modules is large and only needed for the build
cd "$CLIENT_DIR"
rm -rf "$SRC_DIR"

install_dist "${BUILD_DIR}/dist"
echo "$BUILD_ID" > "$STAMP_FILE"

echo "=> tinysub install complete"
