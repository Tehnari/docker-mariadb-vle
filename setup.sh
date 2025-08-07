#!/bin/bash

# Copyright (c) 2025 Constantin Sclifos - sclifcon@gmail.com
# Licensed under MIT License
# MariaDB VLE Setup Script

set -e

echo "Setting up MariaDB VLE..."

# Create necessary directories
mkdir -p data backups logs init scripts exports

# Set proper permissions
chmod 755 scripts/
chmod +x scripts/*.sh

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Please edit .env file with your database credentials"
    echo "Then run: docker compose up -d"
else
    echo ".env file already exists"
fi

echo "Setup completed!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your database credentials"
echo "2. Run: docker compose up -d"
echo "3. Optional: Install as systemd service: sudo ./install.sh"
echo "4. Optional: Setup daily backups: ./scripts/setup-cron.sh"
echo ""
echo "Available scripts:"
echo "  ./scripts/database-migrate.sh  # Interactive database migration tool"
echo "  ./scripts/database-export.sh   # Export databases from container"
echo "  ./scripts/backup-create.sh     # Create manual backup"
echo "  ./scripts/backup-restore.sh    # Restore from backup"
echo "  ./scripts/backup-list.sh       # List available backups"
echo "  ./scripts/backup-cleanup.sh    # Cleanup old backups"
