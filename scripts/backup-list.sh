#!/bin/bash

BACKUP_DIR="./backups"

echo "Available compressed backups:"
echo "============================"

if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]; then
    echo ""
    echo "Backup Files:"
    echo "-------------"
    ls -lah "$BACKUP_DIR"/*.tar.gz 2>/dev/null | while read -r line; do
        echo "$line"
    done
    
    echo ""
    echo "Checksum Files:"
    echo "---------------"
    ls -lah "$BACKUP_DIR"/*.sha256 2>/dev/null | while read -r line; do
        echo "$line"
    done
    
    echo ""
    echo "Summary:"
    echo "--------"
    echo "Total compressed backups: $(find "$BACKUP_DIR" -name "*.tar.gz" | wc -l)"
    echo "Total checksum files: $(find "$BACKUP_DIR" -name "*.sha256" | wc -l)"
    echo "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)"
    
    # Show backup details
    echo ""
    echo "Backup Details:"
    echo "---------------"
    for backup in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$backup" ]; then
            filename=$(basename "$backup")
            size=$(du -h "$backup" | cut -f1)
            date=$(stat -c %y "$backup" | cut -d' ' -f1)
            echo "  $filename ($size, created: $date)"
        fi
    done
else
    echo "No compressed backups found in $BACKUP_DIR"
fi