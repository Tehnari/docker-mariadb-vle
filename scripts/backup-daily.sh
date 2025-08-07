#!/bin/bash

# Copyright (c) 2025 Constantin Sclifos - sclifcon@gmail.com
# Licensed under MIT License
# Daily automated backup script for MariaDB VLE
# This script should be called by cron for daily backups

set -e

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

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

echo "$(date): Starting daily backup: ${BACKUP_FILE}"

# Use mariadb-backup for full backup with compression
docker compose exec -T mariadb mariadb-backup \
  --backup \
  --target-dir=/tmp/backup \
  --user=root \
  --password="${MYSQL_ROOT_PASSWORD}" \
  --stream=xbstream | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    # Create checksum for verification
    sha256sum "${BACKUP_DIR}/${BACKUP_FILE}" > "${BACKUP_DIR}/${BACKUP_NAME}.sha256"
    
    echo "$(date): Daily backup completed successfully: ${BACKUP_FILE}"
    echo "$(date): Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)"
    
    # Cleanup old backups
    ./scripts/backup-cleanup.sh
    
    exit 0
else
    echo "$(date): Daily backup failed!"
    exit 1
fi
