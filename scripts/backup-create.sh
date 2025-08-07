#!/bin/bash

# Copyright (c) 2025 Constantin Sclifos - sclifcon@gmail.com
# Licensed under MIT License
# Create manual backup using mariadb-backup with compression

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mariadb_backup_${TIMESTAMP}"
BACKUP_FILE="${BACKUP_NAME}.tar.gz"

echo "Creating manual backup: ${BACKUP_FILE}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Use mariadb-backup for full backup with compression
docker compose exec -T mariadb mariadb-backup \
  --backup \
  --target-dir=/tmp/backup \
  --user=root \
  --password="${MYSQL_ROOT_PASSWORD}" \
  --stream=xbstream | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    echo "Backup created successfully: ${BACKUP_FILE}"
    echo "Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)"
    
    # Create a checksum for verification
    sha256sum "${BACKUP_DIR}/${BACKUP_FILE}" > "${BACKUP_DIR}/${BACKUP_NAME}.sha256"
    echo "Checksum created: ${BACKUP_NAME}.sha256"
else
    echo "Backup failed!"
    exit 1
fi