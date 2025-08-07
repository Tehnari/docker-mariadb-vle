#!/bin/bash

# Copyright (c) 2025 Constantin Sclifos - sclifcon@gmail.com
# Licensed under MIT License
# MariaDB VLE Systemd Service Installation Script

set -e

echo "Installing MariaDB VLE Docker Compose Service..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Get the current directory
CURRENT_DIR=$(pwd)

# Copy service file to systemd
cp docker-mariadb-vle.service /etc/systemd/system/

# Update the WorkingDirectory in the service file
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$CURRENT_DIR|g" /etc/systemd/system/docker-mariadb-vle.service

# Reload systemd
systemctl daemon-reload

# Enable the service
systemctl enable docker-mariadb-vle.service

echo "Service installed successfully!"
echo ""
echo "Available commands:"
echo "  sudo systemctl start docker-mariadb-vle    # Start the service"
echo "  sudo systemctl stop docker-mariadb-vle     # Stop the service"
echo "  sudo systemctl restart docker-mariadb-vle  # Restart the service"
echo "  sudo systemctl status docker-mariadb-vle   # Check service status"
echo "  sudo systemctl enable docker-mariadb-vle   # Enable auto-start"
echo "  sudo systemctl disable docker-mariadb-vle  # Disable auto-start"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u docker-mariadb-vle -f"
