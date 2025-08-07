#!/bin/bash

# Setup cron job for daily MariaDB backups
# This script adds a cron job to run daily backups at 2:00 AM

set -e

# Get the absolute path to the backup script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup-daily.sh"

# Check if backup script exists
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "Error: backup-daily.sh not found at $BACKUP_SCRIPT"
    exit 1
fi

# Make sure the script is executable
chmod +x "$BACKUP_SCRIPT"

# Create cron job entry (daily at 2:00 AM)
CRON_JOB="0 2 * * * cd $(dirname "$SCRIPT_DIR") && $BACKUP_SCRIPT >> ./logs/backup.log 2>&1"

echo "Setting up daily backup cron job..."
echo "Cron job will run: $CRON_JOB"
echo ""

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "backup-daily.sh"; then
    echo "Cron job already exists. Removing old entry..."
    crontab -l 2>/dev/null | grep -v "backup-daily.sh" | crontab -
fi

# Add new cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Cron job added successfully!"
echo ""
echo "Current cron jobs:"
crontab -l
echo ""
echo "Backup logs will be written to: ./logs/backup.log"
echo "To remove the cron job, run: crontab -e"
