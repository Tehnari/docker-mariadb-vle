#!/bin/bash

# MariaDB VLE Initial Setup Script

set -e

echo "Setting up MariaDB VLE (Initial Setup)..."

# Create necessary directories
mkdir -p data backups logs init scripts

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
echo "3. Optional: Install as systemd service: sudo ./scripts/install-systemd.sh"