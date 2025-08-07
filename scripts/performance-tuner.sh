#!/bin/bash

# Copyright (c) 2025 Constantin Sclifos - sclifcon@gmail.com
# Licensed under MIT License

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Function to print colored output
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
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to get system information
get_system_info() {
    print_header "System Information"
    
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
    calculate_recommendations
}

# Function to calculate recommended settings
calculate_recommendations() {
    print_header "Performance Recommendations"
    
    # Calculate InnoDB Buffer Pool Size (conservative values for stable operation)
    if [ "$TOTAL_RAM" -gt 16384 ]; then
        # Very large system (>16GB RAM) - balanced for large databases
        # Use 16GB buffer pool for systems with 32GB+ RAM
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
    
    # Calculate InnoDB Log File Size (balanced: 25% of buffer pool, max 2GB for large databases)
    INNODB_LOG_FILE_SIZE=$((INNODB_BUFFER_POOL_SIZE * 25 / 100))
    if [ "$INNODB_LOG_FILE_SIZE" -gt 2048 ]; then
        INNODB_LOG_FILE_SIZE=2048
    fi
    print_status "Recommended InnoDB Log File Size: ${INNODB_LOG_FILE_SIZE}M (balanced for large databases)"
    
    # Calculate Max Connections (balanced: CPU cores × 40, max 800 for large databases)
    MAX_CONNECTIONS=$((CPU_CORES * 40))
    if [ "$MAX_CONNECTIONS" -gt 800 ]; then
        MAX_CONNECTIONS=800
    fi
    print_status "Recommended Max Connections: ${MAX_CONNECTIONS} (balanced for large databases)"
    
    # Calculate Query Cache Size (5% of available RAM, max 128M)
    QUERY_CACHE_SIZE=$((AVAILABLE_RAM * 5 / 100))
    if [ "$QUERY_CACHE_SIZE" -gt 128 ]; then
        QUERY_CACHE_SIZE=128
    fi
    print_status "Recommended Query Cache Size: ${QUERY_CACHE_SIZE}M"
    
    # Calculate Temp Table Size (based on available RAM)
    TMP_TABLE_SIZE=$((AVAILABLE_RAM * 10 / 100))
    if [ "$TMP_TABLE_SIZE" -gt 512 ]; then
        TMP_TABLE_SIZE=512
    fi
    print_status "Recommended Temp Table Size: ${TMP_TABLE_SIZE}M"
    
    # Calculate Max Heap Table Size (same as temp table size)
    MAX_HEAP_TABLE_SIZE=$TMP_TABLE_SIZE
    print_status "Recommended Max Heap Table Size: ${MAX_HEAP_TABLE_SIZE}M"
}

# Function to show database size recommendations
show_database_recommendations() {
    print_header "Database Size Recommendations"
    
    echo "Based on your system resources, here are recommendations for different database sizes:"
    echo ""
    
    if [ "$TOTAL_RAM" -gt 16384 ]; then
        echo "🟢 Very Large System (>16GB RAM) - Suitable for:"
        echo "   • Very large databases (25GB+)"
        echo "   • High concurrent users (200+)"
        echo "   • Complex queries and reporting"
        echo "   • Production environments"
        echo "   • InnoDB Log File: 2GB (adequate for large transactions)"
    elif [ "$TOTAL_RAM" -gt 8192 ]; then
        echo "🟢 Large System (8-16GB RAM) - Suitable for:"
        echo "   • Large databases (10-25GB)"
        echo "   • High concurrent users (100+)"
        echo "   • Complex queries and reporting"
        echo "   • Production environments"
        echo "   • InnoDB Log File: 1GB (adequate for large transactions)"
    elif [ "$TOTAL_RAM" -gt 4096 ]; then
        echo "🟡 Medium System (4-8GB RAM) - Suitable for:"
        echo "   • Medium databases (1-10GB)"
        echo "   • Moderate concurrent users (20-100)"
        echo "   • Development and testing"
        echo "   • Small to medium production"
        echo "   • InnoDB Log File: 512MB (adequate for medium transactions)"
    else
        echo "🔴 Small System (<4GB RAM) - Suitable for:"
        echo "   • Small databases (<1GB)"
        echo "   • Low concurrent users (<20)"
        echo "   • Development and testing only"
        echo "   • Not recommended for production"
        echo "   • InnoDB Log File: 256MB (adequate for small transactions)"
    fi
    
    echo ""
    echo "💡 Performance Tips:"
    echo "   • Monitor memory usage with: docker stats mariadb-vle"
    echo "   • Check slow queries: docker compose exec mariadb mariadb -u root -p -e 'SHOW VARIABLES LIKE \"slow_query_log\";'"
    echo "   • Optimize queries and add indexes for better performance"
    echo "   • Consider SSD storage for better I/O performance"
}

# Function to generate optimized .env configuration
generate_optimized_config() {
    print_header "Generate Optimized Configuration"
    
    # Create backup of current .env
    if [ -f .env ]; then
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        print_status "Backup created: .env.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Generate optimized .env content
    cat > .env.optimized << EOF
# MariaDB Configuration
# Generated by performance-tuner.sh on $(date)
# Example of password is below. Is only for demonstration. In production you MUST change it!
MYSQL_ROOT_PASSWORD=your_secure_root_password_here
MYSQL_DATABASE=vledb
MYSQL_USER=vledb_user
MYSQL_PASSWORD=your_secure_user_password_here
MYSQL_PORT=3366

# Source Database Configuration (for migration)
SOURCE_MYSQL_USER=root
SOURCE_MYSQL_PASSWORD=your_secure_source_password_here

# Backup Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_TIME=02:00

# MariaDB Character Set Configuration
# Available options: utf8mb4, utf8, latin1, etc.
MARIADB_CHARACTER_SET_SERVER=utf8mb4
MARIADB_COLLATION_SERVER=utf8mb4_unicode_ci

# MariaDB Performance Configuration
# Optimized for your system: ${TOTAL_RAM}MB RAM, ${CPU_CORES} CPU cores
MARIADB_INNODB_BUFFER_POOL_SIZE=${INNODB_BUFFER_POOL_SIZE}M
MARIADB_INNODB_LOG_FILE_SIZE=${INNODB_LOG_FILE_SIZE}M
MARIADB_MAX_CONNECTIONS=${MAX_CONNECTIONS}
MARIADB_QUERY_CACHE_SIZE=${QUERY_CACHE_SIZE}M
MARIADB_TMP_TABLE_SIZE=${TMP_TABLE_SIZE}M
MARIADB_MAX_HEAP_TABLE_SIZE=${MAX_HEAP_TABLE_SIZE}M

# Health Check Configuration
MARIADB_HEALTH_CHECK_INTERVAL=30s
MARIADB_HEALTH_CHECK_TIMEOUT=10s
MARIADB_HEALTH_CHECK_RETRIES=3
MARIADB_HEALTH_CHECK_START_PERIOD=60s
EOF
    
    print_status "Optimized configuration generated: .env.optimized"
    print_warning "Please review .env.optimized and copy to .env if satisfied"
    print_warning "Remember to update passwords in production!"
}

# Function to show current configuration
show_current_config() {
    print_header "Current Configuration"
    
    if [ -f .env ]; then
        echo "Current .env settings:"
        grep -E "MARIADB_|MYSQL_" .env | grep -v PASSWORD || echo "No MariaDB performance settings found in .env"
    else
        print_warning "No .env file found"
    fi
    
    echo ""
    echo "Current Docker Compose settings:"
    docker compose config 2>/dev/null | grep -A 20 "command:" || print_warning "Docker Compose not running or no configuration found"
}

# Function to apply performance settings
apply_performance_settings() {
    print_header "Apply Performance Settings"
    
    if [ ! -f .env.optimized ]; then
        print_error "No optimized configuration found. Run with --generate first."
        exit 1
    fi
    
    print_warning "This will replace your current .env file with optimized settings."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp .env.optimized .env
        print_status "Performance settings applied to .env"
        print_status "Restart the container to apply changes:"
        echo "  docker compose down"
        echo "  docker compose up -d"
    else
        print_status "Operation cancelled"
    fi
}

# Function to show usage
show_usage() {
    echo "MariaDB Performance Tuner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --analyze          Analyze system and show recommendations"
    echo "  --generate         Generate optimized .env configuration"
    echo "  --apply            Apply optimized configuration to .env"
    echo "  --current          Show current configuration"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --analyze       # Analyze system and show recommendations"
    echo "  $0 --generate      # Generate optimized .env.optimized file"
    echo "  $0 --apply         # Apply optimized settings to .env"
    echo "  $0 --current       # Show current configuration"
}

# Main function
main() {
    case "${1:-}" in
        --analyze)
            get_system_info
            show_database_recommendations
            ;;
        --generate)
            get_system_info
            generate_optimized_config
            ;;
        --apply)
            apply_performance_settings
            ;;
        --current)
            show_current_config
            ;;
        --help|"")
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
