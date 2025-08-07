#!/bin/bash

# Copyright (c) 2025 Constantin Sclifos - sclifcon@gmail.com
# Licensed under MIT License
# MariaDB VLE Complete Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  MariaDB VLE Setup${NC}"
    echo -e "${BLUE}================================${NC}"
}

show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --instance-name NAME    Set instance name (default: mariadb-vle)"
    echo "  --port PORT            Set port (default: 3366)"
    echo "  --install-systemd      Install as systemd service"
    echo "  --setup-cron           Setup daily backups"
    echo "  --reset                Reset to template level (remove all configuration)"
    echo "  --help                 Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Basic setup with defaults"
    echo "  $0 --instance-name production --port 3367"
    echo "  $0 --instance-name staging --port 3368 --install-systemd"
    echo "  $0 --instance-name dev --port 3369 --setup-cron"
    echo "  $0 --reset                            # Reset to template level"
}

setup_instance() {
    local INSTANCE_NAME="$1"
    local INSTANCE_PORT="$2"
    
    print_status "Setting up instance: $INSTANCE_NAME on port $INSTANCE_PORT"
    
    # Create necessary directories
    print_status "Creating directories..."
    mkdir -p data backups logs init scripts exports migrations/exports migrations/imports
    
    # Set proper permissions
    chmod 755 scripts/
    chmod +x scripts/*.sh
    
    # Copy environment file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Creating .env file from template..."
        cp .env.example .env
    fi
    
    # Update .env with instance configuration
    print_status "Configuring instance settings..."
    sed -i "s/INSTANCE_NAME=.*/INSTANCE_NAME=${INSTANCE_NAME}/g" .env
    sed -i "s/INSTANCE_PORT=.*/INSTANCE_PORT=${INSTANCE_PORT}/g" .env
    
    # Generate docker-compose.yml from template
    print_status "Generating docker-compose.yml from template..."
    sed "s/{{INSTANCE_NAME}}/${INSTANCE_NAME}/g; s/{{INSTANCE_PORT}}/${INSTANCE_PORT}/g" docker-compose.template.yml > docker-compose.yml
    
    print_status "✓ Instance setup completed!"
}

install_systemd() {
    local INSTANCE_NAME="$1"
    
    print_status "Installing as systemd service..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo) for systemd installation"
        return 1
    fi
    
    # Get the current directory
    CURRENT_DIR=$(pwd)
    
    # Generate service file from template
    print_status "Generating systemd service file..."
    sed "s/{{INSTANCE_NAME}}/${INSTANCE_NAME}/g; s|{{WORKING_DIRECTORY}}|${CURRENT_DIR}|g" docker-mariadb-vle.service.template > docker-${INSTANCE_NAME}.service
    
    # Copy service file to systemd
    cp docker-${INSTANCE_NAME}.service /etc/systemd/system/
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable the service
    systemctl enable docker-${INSTANCE_NAME}.service
    
    print_status "✓ Systemd service installed successfully!"
    echo ""
    echo "Available commands:"
    echo "  sudo systemctl start docker-${INSTANCE_NAME}    # Start the service"
    echo "  sudo systemctl stop docker-${INSTANCE_NAME}     # Stop the service"
    echo "  sudo systemctl restart docker-${INSTANCE_NAME}  # Restart the service"
    echo "  sudo systemctl status docker-${INSTANCE_NAME}   # Check service status"
}

setup_cron() {
    print_status "Setting up daily backup cron job..."
    
    # Get the absolute path to the backup script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BACKUP_SCRIPT="${SCRIPT_DIR}/backup-daily.sh"
    
    # Check if backup script exists
    if [ ! -f "$BACKUP_SCRIPT" ]; then
        print_error "backup-daily.sh not found at $BACKUP_SCRIPT"
        return 1
    fi
    
    # Make sure the script is executable
    chmod +x "$BACKUP_SCRIPT"
    
    # Create cron job entry (daily at 2:00 AM)
    CRON_JOB="0 2 * * * cd $(dirname "$SCRIPT_DIR") && $BACKUP_SCRIPT >> ./logs/backup.log 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "backup-daily.sh"; then
        print_warning "Cron job already exists. Removing old entry..."
        crontab -l 2>/dev/null | grep -v "backup-daily.sh" | crontab -
    fi
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    
    print_status "✓ Cron job added successfully!"
    echo ""
    echo "Backup logs will be written to: ./logs/backup.log"
}

reset_to_template() {
    print_status "Resetting to template level..."
    
    # Stop and remove containers if running
    if [ -f "docker-compose.yml" ]; then
        print_status "Stopping containers..."
        docker compose down 2>/dev/null || true
    fi
    
    # Remove generated files
    print_status "Removing generated files..."
    rm -f docker-compose.yml
    rm -f docker-*.service
    
    # Reset .env to template
    if [ -f ".env.example" ]; then
        print_status "Resetting .env to template..."
        cp .env.example .env
    fi
    
    # Remove data directories (but keep structure)
    print_status "Clearing data directories..."
    rm -rf data/* 2>/dev/null || true
    rm -rf backups/* 2>/dev/null || true
    rm -rf logs/* 2>/dev/null || true
    rm -rf migrations/exports/* 2>/dev/null || true
    rm -rf migrations/imports/* 2>/dev/null || true
    rm -rf exports/* 2>/dev/null || true
    
    # Remove cron jobs
    print_status "Removing cron jobs..."
    crontab -l 2>/dev/null | grep -v "backup-daily.sh" | crontab - 2>/dev/null || true
    
    print_status "✓ Reset completed successfully!"
    echo ""
    echo "📋 Project is now at template level:"
    echo "  - No docker-compose.yml (will be generated from template)"
    echo "  - .env reset to template values"
    echo "  - All data directories cleared"
    echo "  - Cron jobs removed"
    echo "  - No containers running"
    echo ""
    echo "🔧 Next steps:"
    echo "  - Run setup again with your desired configuration"
    echo "  - Example: ./scripts/setup.sh --instance-name production --port 3367"
}

main() {
    print_header
    
    # Default values
    INSTANCE_NAME="mariadb-vle"
    INSTANCE_PORT="3366"
    INSTALL_SYSTEMD=false
    SETUP_CRON=false
    RESET_TEMPLATE=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --instance-name)
                INSTANCE_NAME="$2"
                shift 2
                ;;
            --port)
                INSTANCE_PORT="$2"
                shift 2
                ;;
            --install-systemd)
                INSTALL_SYSTEMD=true
                shift
                ;;
            --setup-cron)
                SETUP_CRON=true
                shift
                ;;
            --reset)
                RESET_TEMPLATE=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate instance name
    if [[ ! "$INSTANCE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Instance name must contain only letters, numbers, hyphens, and underscores"
        exit 1
    fi
    
    # Validate port
    if [[ ! "$INSTANCE_PORT" =~ ^[0-9]+$ ]] || [ "$INSTANCE_PORT" -lt 1024 ] || [ "$INSTANCE_PORT" -gt 65535 ]; then
        print_error "Port must be a number between 1024 and 65535"
        exit 1
    fi
    
    # Handle reset option
    if [ "$RESET_TEMPLATE" = true ]; then
        reset_to_template
        exit 0
    fi
    
    # Check if templates exist
    if [ ! -f "docker-compose.template.yml" ]; then
        print_error "docker-compose.template.yml not found"
        exit 1
    fi
    
    if [ ! -f "docker-mariadb-vle.service.template" ]; then
        print_error "docker-mariadb-vle.service.template not found"
        exit 1
    fi
    
    # Setup instance
    setup_instance "$INSTANCE_NAME" "$INSTANCE_PORT"
    
    # Install systemd service if requested
    if [ "$INSTALL_SYSTEMD" = true ]; then
        install_systemd "$INSTANCE_NAME"
    fi
    
    # Setup cron if requested
    if [ "$SETUP_CRON" = true ]; then
        setup_cron
    fi
    
    echo ""
    print_status "Setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Set proper passwords in .env file"
    echo "  2. Run: docker compose up -d"
    echo ""
    echo "🔧 Instance configuration:"
    echo "  - Instance Name: $INSTANCE_NAME"
    echo "  - Port: $INSTANCE_PORT"
    echo "  - Network: ${INSTANCE_NAME}-network"
    echo ""
    echo "⚠️  IMPORTANT: Set proper passwords in .env before starting!"
}

# Run main function
main "$@"
