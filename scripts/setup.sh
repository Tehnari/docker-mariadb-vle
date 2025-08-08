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

# Function to generate secure MariaDB-compatible password
generate_password() {
    # Generate a 12-character password with:
    # - At least 1 uppercase letter
    # - At least 1 lowercase letter  
    # - At least 1 number
    # - At least 1 special character (simpler ones for MariaDB compatibility)
    # - No problematic characters for MariaDB
    
    # Define character sets
    UPPER="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    LOWER="abcdefghijklmnopqrstuvwxyz"
    NUMBERS="0123456789"
    SPECIAL=""  # No special characters to avoid any compatibility issues
    
    # Generate password components
    password=""
    password+="${UPPER:$((RANDOM % ${#UPPER})):1}"  # 1 uppercase
    password+="${LOWER:$((RANDOM % ${#LOWER})):1}"  # 1 lowercase
    password+="${NUMBERS:$((RANDOM % ${#NUMBERS})):1}"  # 1 number
    
    # Fill remaining 9 characters with mixed characters (no special chars)
    ALL_CHARS="${UPPER}${LOWER}${NUMBERS}"
    for i in {1..9}; do
        password+="${ALL_CHARS:$((RANDOM % ${#ALL_CHARS})):1}"
    done
    
    # Shuffle the password
    echo "$password" | fold -w1 | shuf | tr -d '\n'
}

# Function to get system information and calculate performance settings
get_system_info() {
    # Get total RAM
    TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    AVAILABLE_RAM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    
    # Get CPU cores
    CPU_CORES=$(nproc)
    
    # Get disk space
    DISK_SPACE=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
    
    print_status "Total RAM: ${TOTAL_RAM}MB"
    print_status "Available RAM: ${AVAILABLE_RAM}MB"
    print_status "CPU Cores: ${CPU_CORES}"
    print_status "Available Disk Space: ${DISK_SPACE}GB"
    
    # Calculate recommended settings
    calculate_performance_settings
}

# Function to calculate performance settings
calculate_performance_settings() {
    print_status "Calculating performance settings..."
    
    # If user provided a buffer pool percentage (50-70), use it
    if [ -n "$BUFFER_POOL_PERCENT" ]; then
        if [[ ! "$BUFFER_POOL_PERCENT" =~ ^[0-9]+$ ]] || [ "$BUFFER_POOL_PERCENT" -lt 50 ] || [ "$BUFFER_POOL_PERCENT" -gt 70 ]; then
            print_warning "Invalid --buffer-pool-percent value '$BUFFER_POOL_PERCENT'. Falling back to automatic sizing."
        else
            INNODB_BUFFER_POOL_SIZE=$(( TOTAL_RAM * BUFFER_POOL_PERCENT / 100 ))
            print_status "Using buffer pool percent: ${BUFFER_POOL_PERCENT}% of RAM → ${INNODB_BUFFER_POOL_SIZE}M"
        fi
    fi

    # Automatic sizing if not set via percent
    if [ -z "$INNODB_BUFFER_POOL_SIZE" ]; then
        # Calculate InnoDB Buffer Pool Size (conservative values for stable operation)
        if [ "$TOTAL_RAM" -gt 16384 ]; then
            # Very large system (>16GB RAM) - balanced for large databases
            INNODB_BUFFER_POOL_SIZE=16384
            print_status "Very large system detected (>16GB RAM)"
            print_status "Recommended InnoDB Buffer Pool: ${INNODB_BUFFER_POOL_SIZE}M (balanced for large databases)"
        elif [ "$TOTAL_RAM" -gt 8192 ]; then
            # Large system (8-16GB RAM) - max 4GB buffer pool
            INNODB_BUFFER_POOL_SIZE=4096
            print_status "Large system detected (8-16GB RAM)"
            print_status "Recommended InnoDB Buffer Pool: ${INNODB_BUFFER_POOL_SIZE}M (conservative)"
        elif [ "$TOTAL_RAM" -gt 4096 ]; then
            # Medium system (4-8GB RAM) - max 2GB buffer pool
            INNODB_BUFFER_POOL_SIZE=2048
            print_status "Medium system detected (4-8GB RAM)"
            print_status "Recommended InnoDB Buffer Pool: ${INNODB_BUFFER_POOL_SIZE}M (conservative)"
        else
            # Small system (<4GB RAM) - max 1GB buffer pool
            INNODB_BUFFER_POOL_SIZE=1024
            print_status "Small system detected (<4GB RAM)"
            print_status "Recommended InnoDB Buffer Pool: ${INNODB_BUFFER_POOL_SIZE}M (conservative)"
        fi
    fi
    
    # Calculate InnoDB Log File Size (balanced: 25% of buffer pool, max 2GB for large databases)
    INNODB_LOG_FILE_SIZE=$((INNODB_BUFFER_POOL_SIZE * 25 / 100))
    if [ "$INNODB_LOG_FILE_SIZE" -gt 2048 ]; then
        INNODB_LOG_FILE_SIZE=2048
    fi
    print_status "Recommended InnoDB Log File Size: ${INNODB_LOG_FILE_SIZE}M (balanced for large databases)"
    
    # Calculate Max Connections
    local base_connections=$((CPU_CORES * 40))
    MAX_CONNECTIONS=$base_connections
    
    # If target clients provided, ensure we meet or exceed it
    if [ -n "$TARGET_CLIENTS" ]; then
        if [[ "$TARGET_CLIENTS" =~ ^[0-9]+$ ]] && [ "$TARGET_CLIENTS" -gt 0 ]; then
            if [ "$TARGET_CLIENTS" -gt "$MAX_CONNECTIONS" ]; then
                MAX_CONNECTIONS=$TARGET_CLIENTS
            fi
        else
            print_warning "Invalid --target-clients value '$TARGET_CLIENTS'. Using computed value ${MAX_CONNECTIONS}."
        fi
    fi
    
    # Apply an upper safety cap to prevent extreme settings
    local max_cap=5000
    if [ "$MAX_CONNECTIONS" -gt "$max_cap" ]; then
        print_warning "Capping max_connections from ${MAX_CONNECTIONS} to ${max_cap} to avoid excessive resource usage"
        MAX_CONNECTIONS=$max_cap
    fi
    print_status "Max Connections set to: ${MAX_CONNECTIONS} (CPU baseline ${base_connections}${TARGET_CLIENTS:+, target ${TARGET_CLIENTS}})"
    
    # Calculate other settings
    QUERY_CACHE_SIZE=128
    TMP_TABLE_SIZE=512
    MAX_HEAP_TABLE_SIZE=512
    
    print_status "Recommended Query Cache Size: ${QUERY_CACHE_SIZE}M"
    print_status "Recommended Temp Table Size: ${TMP_TABLE_SIZE}M"
    print_status "Recommended Max Heap Table Size: ${MAX_HEAP_TABLE_SIZE}M"
}

# Function to apply performance settings to .env
apply_performance_settings() {
    print_status "Applying performance settings to .env..."
    
    # Create backup of current .env
    if [ -f .env ]; then
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        print_status "Backup created: .env.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Update performance settings in .env
    sed -i "s/MARIADB_INNODB_BUFFER_POOL_SIZE=.*/MARIADB_INNODB_BUFFER_POOL_SIZE=${INNODB_BUFFER_POOL_SIZE}M/" .env
    sed -i "s/MARIADB_INNODB_LOG_FILE_SIZE=.*/MARIADB_INNODB_LOG_FILE_SIZE=${INNODB_LOG_FILE_SIZE}M/" .env
    sed -i "s/MARIADB_MAX_CONNECTIONS=.*/MARIADB_MAX_CONNECTIONS=${MAX_CONNECTIONS}/" .env
    sed -i "s/MARIADB_QUERY_CACHE_SIZE=.*/MARIADB_QUERY_CACHE_SIZE=${QUERY_CACHE_SIZE}M/" .env
    sed -i "s/MARIADB_TMP_TABLE_SIZE=.*/MARIADB_TMP_TABLE_SIZE=${TMP_TABLE_SIZE}M/" .env
    sed -i "s/MARIADB_MAX_HEAP_TABLE_SIZE=.*/MARIADB_MAX_HEAP_TABLE_SIZE=${MAX_HEAP_TABLE_SIZE}M/" .env
    
    print_status "✓ Performance settings applied to .env"
    print_warning "Restart the container to apply changes: docker compose down && docker compose up -d"
}

# Function to update passwords in .env.example
update_passwords() {
    print_status "Generating new secure passwords..."
    
    # Generate new passwords
    ROOT_PASSWORD=$(generate_password)
    USER_PASSWORD=$(generate_password)
    
    print_status "Generated Root Password: $ROOT_PASSWORD"
    print_status "Generated User Password: $USER_PASSWORD"
    
    # Create backup of current .env.example
    if [ -f .env.example ]; then
        cp .env.example .env.example.backup.$(date +%Y%m%d_%H%M%S)
        print_status "Backup created: .env.example.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Update .env.example with new passwords
    sed -i "s/MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=$ROOT_PASSWORD/" .env.example
    sed -i "s/MYSQL_PASSWORD=.*/MYSQL_PASSWORD=$USER_PASSWORD/" .env.example
    
    print_status "✓ .env.example updated with new passwords"
    print_warning "Remember to update passwords in production environments!"
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
    echo "  --update-passwords     Generate new secure passwords for .env.example"
    echo "  --optimize-performance Analyze system and apply performance settings"
    echo "  --buffer-pool-percent P Set InnoDB buffer pool to P% of total RAM (50-70)"
    echo "  --target-clients N     Target concurrent clients (influences max_connections)"
    echo "  --help                 Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Basic setup with defaults"
    echo "  $0 --instance-name production --port 3367"
    echo "  $0 --instance-name staging --port 3368 --install-systemd"
    echo "  $0 --instance-name dev --port 3369 --setup-cron"
    echo "  $0 --reset                            # Reset to template level"
    echo "  $0 --update-passwords                 # Generate new passwords"
    echo "  $0 --optimize-performance            # Analyze and optimize performance"
    echo "  $0 --optimize-performance --buffer-pool-percent 60 --target-clients 800"
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
    
    # Remove backup and temporary files
    print_status "Removing backup and temporary files..."
    rm -f .env.backup.*
    rm -f .env.example.backup.*
    rm -f .env.optimized
    
    # Remove .env file to return to template state
    if [ -f ".env" ]; then
        print_status "Removing .env file to return to template state..."
        rm .env
    fi
    
    # Remove data directories (but keep structure)
    print_status "Clearing data directories..."
    sudo rm -rf data/* data/.* 2>/dev/null || true
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
    UPDATE_PASSWORDS=false
    OPTIMIZE_PERFORMANCE=false
    BUFFER_POOL_PERCENT=""
    TARGET_CLIENTS=""
    
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
            --update-passwords)
                UPDATE_PASSWORDS=true
                shift
                ;;
            --optimize-performance)
                OPTIMIZE_PERFORMANCE=true
                shift
                ;;
            --buffer-pool-percent)
                BUFFER_POOL_PERCENT="$2"
                shift 2
                ;;
            --target-clients)
                TARGET_CLIENTS="$2"
                shift 2
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
    
    # Handle password update option
    if [ "$UPDATE_PASSWORDS" = true ]; then
        update_passwords
        exit 0
    fi
    
    # Handle performance optimization option
    if [ "$OPTIMIZE_PERFORMANCE" = true ]; then
        get_system_info
        apply_performance_settings
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
