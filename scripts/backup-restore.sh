#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    echo "Available backups:"
    ls -la ./backups/*.tar.gz 2>/dev/null || echo "No compressed backups found"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_DIR="./backups"

# Remove .tar.gz extension if provided
BACKUP_NAME="${BACKUP_FILE%.tar.gz}"
BACKUP_NAME="${BACKUP_NAME%.sql}"

# Check if file exists
if [ ! -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    echo "Backup file not found: ${BACKUP_FILE}"
    echo "Available backups:"
    ls -la "${BACKUP_DIR}/"*.tar.gz 2>/dev/null || echo "No compressed backups found"
    exit 1
fi

# Verify checksum if available
CHECKSUM_FILE="${BACKUP_DIR}/${BACKUP_NAME}.sha256"
if [ -f "$CHECKSUM_FILE" ]; then
    echo "Verifying backup integrity..."
    cd "$BACKUP_DIR"
    if sha256sum -c "${BACKUP_NAME}.sha256"; then
        echo "Backup integrity verified"
    else
        echo "Backup integrity check failed!"
        exit 1
    fi
    cd - > /dev/null
fi

echo "Restoring from backup: ${BACKUP_FILE}"
echo "This will overwrite the current database. Continue? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Stopping MariaDB service..."
    docker compose stop mariadb
    
    echo "Cleaning existing data..."
    docker compose exec mariadb rm -rf /var/lib/mysql/*
    
    echo "Restoring backup..."
    # Extract and restore using mariadb-backup
    gunzip -c "${BACKUP_DIR}/${BACKUP_FILE}" | \
    docker compose exec -T mariadb mariadb-backup \
      --copy-back \
      --target-dir=/tmp/restore \
      --user=root \
      --password="${MYSQL_ROOT_PASSWORD}"
    
    if [ $? -eq 0 ]; then
        echo "Restore completed successfully"
        echo "Starting MariaDB service..."
        docker compose start mariadb
    else
        echo "Restore failed!"
        exit 1
    fi
else
    echo "Restore cancelled"
fi