#!/bin/bash

# Cleanup old compressed backups based on retention policy
BACKUP_DIR="./backups"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

echo "Cleaning up compressed backups older than ${RETENTION_DAYS} days..."

# Count files before cleanup
BEFORE_COUNT=$(find "$BACKUP_DIR" -name "*.tar.gz" | wc -l)
BEFORE_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")

# Remove old compressed backups
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# Remove corresponding checksum files
find "$BACKUP_DIR" -name "*.sha256" -type f -mtime +$RETENTION_DAYS -delete

# Count files after cleanup
AFTER_COUNT=$(find "$BACKUP_DIR" -name "*.tar.gz" | wc -l)
AFTER_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")

echo "Cleanup completed:"
echo "  Removed $((BEFORE_COUNT - AFTER_COUNT)) backup files"
echo "  Previous size: $BEFORE_SIZE"
echo "  Current size: $AFTER_SIZE"
