#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/ampache.cfg.php"
BACKUP_DIR="${SCRIPT_DIR}/../backup"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}"
    exit 1
fi

MYSQLDUMP="$(command -v mysqldump || true)"

if [[ -z "${MYSQLDUMP}" ]]; then
    echo "ERROR: mysqldump was not found in PATH"
    echo "Install mysql-client or mariadb-client."
    exit 1
fi

get_config_value() {
    local key="$1"

    sed -nE \
        "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"([^\"]*)\".*/\1/p" \
        "${CONFIG_FILE}" | head -n1
}

DB_HOST=$(get_config_value "database_hostname")
DB_NAME=$(get_config_value "database_name")
DB_USER=$(get_config_value "database_username")
DB_PASS=$(get_config_value "database_password")

for var in DB_HOST DB_NAME DB_USER DB_PASS; do
    if [[ -z "${!var}" ]]; then
        echo "ERROR: Failed to read ${var} from ${CONFIG_FILE}"
        exit 1
    fi
done

mkdir -p "${BACKUP_DIR}"

BACKUP_FILE="${BACKUP_DIR}/$(date +%F).sql"

echo "Backing up database '${DB_NAME}' to ${BACKUP_FILE}"

if ! "${MYSQLDUMP}" \
    --host="${DB_HOST}" \
    --user="${DB_USER}" \
    --password="${DB_PASS}" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    "${DB_NAME}" > "${BACKUP_FILE}"; then
    echo "ERROR: Database backup failed"
    echo "host ${DB_HOST}"
    echo "user ${DB_USER}"
    echo "pass ${DB_PASS}"
    rm -f "${BACKUP_FILE}"
    exit 1
fi

echo "Backup complete: ${BACKUP_FILE}"

