#!/bin/bash

# Copyright (c) 2025 Constantin Sclifos - sclifcon@gmail.com
# Licensed under MIT License
# Database Export Script
# Exports specific databases from MariaDB container to host

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Database Export Tool${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if pv is installed
check_pv_installation() {
    if ! command -v pv &> /dev/null; then
        print_warning "pv (pipe viewer) is not installed"
        echo "Progress bars will not be available for database operations."
        echo ""
        echo "To install pv:"
        echo "  Ubuntu/Debian: sudo apt-get install pv"
        echo "  CentOS/RHEL: sudo yum install pv"
        echo "  macOS: brew install pv"
        echo ""
        echo "The script will work without pv, but without progress indicators."
        echo ""
        read -p "Press Enter to continue without pv, or Ctrl+C to install pv first: "
        echo ""
        PV_AVAILABLE=false
    else
        print_status "✓ pv (pipe viewer) is available for progress bars"
        PV_AVAILABLE=true
    fi
}

# Function to check if container is running
check_container() {
    if ! docker compose ps mariadb | tr '\n' ' ' | grep -q "Up"; then
        print_error "MariaDB container is not running!"
        echo "Please start the container first:"
        echo "  docker compose up -d"
        exit 1
    fi
}

# Function to get databases from container
get_container_databases() {
    print_status "Getting databases from container..."
    
    CONTAINER_DBS=()
    while IFS= read -r line; do
        if [[ "$line" != "Database" && "$line" != "information_schema" && "$line" != "performance_schema" && "$line" != "mysql" && "$line" != "sys" ]]; then
            CONTAINER_DBS+=("$line")
        fi
    done < <(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys")
}

# Function to get databases from source (host/local)
get_source_databases() {
    print_status "Getting databases from source (localhost:3306)..."
    
    SOURCE_DBS=()
    
    # Try to connect to source database
    if command -v mysql &> /dev/null; then
        # Try with default credentials or prompt for them
        if [ -n "$SOURCE_MYSQL_USER" ] && [ -n "$SOURCE_MYSQL_PASSWORD" ]; then
            while IFS= read -r line; do
                if [[ "$line" != "Database" && "$line" != "information_schema" && "$line" != "performance_schema" && "$line" != "mysql" && "$line" != "sys" ]]; then
                    SOURCE_DBS+=("$line")
                fi
            done < <(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys")
        else
            print_warning "Source database credentials not provided"
            read -p "Enter source MySQL username: " SOURCE_MYSQL_USER
            read -s -p "Enter source MySQL password: " SOURCE_MYSQL_PASSWORD
            echo ""
            
            while IFS= read -r line; do
                if [[ "$line" != "Database" && "$line" != "information_schema" && "$line" != "performance_schema" && "$line" != "mysql" && "$line" != "sys" ]]; then
                    SOURCE_DBS+=("$line")
                fi
            done < <(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys")
        fi
    else
        print_error "MySQL client not found. Please install mysql-client or mariadb-client"
        return 1
    fi
    
    if [ ${#SOURCE_DBS[@]} -eq 0 ]; then
        print_warning "No databases found on source or connection failed"
        echo "Please check your source database connection"
    fi
}

# Function to generate metadata for database export
generate_metadata() {
    local db_name="$1"
    local export_dir="$2"
    local timestamp="$3"
    local compress="$4"
    
    # Get database information
    local tables_count=$(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$db_name';" 2>/dev/null | tail -n 1)
    local routines_count=$(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = '$db_name';" 2>/dev/null | tail -n 1)
    local triggers_count=$(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = '$db_name';" 2>/dev/null | tail -n 1)
    local db_size=$(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '$db_name';" 2>/dev/null | tail -n 1)
    
    # Create metadata JSON
    local metadata_file="${export_dir}/metadata.json"
    cat > "$metadata_file" << EOF
{
  "export_info": {
    "timestamp": "$(date -Iseconds)",
    "source_host": "container:3366",
    "source_user": "root",
    "export_tool": "database-export.sh",
    "export_type": "migration"
  },
  "database_info": {
    "original_name": "$db_name",
    "size_mb": ${db_size:-0},
    "tables_count": ${tables_count:-0},
    "routines_count": ${routines_count:-0},
    "triggers_count": ${triggers_count:-0}
  },
  "export_options": {
    "compressed": true,
    "include_routines": true,
    "include_triggers": true,
    "single_transaction": true
  },
  "files": {
    "database_file": "database.sql.gz",
    "metadata_file": "metadata.json",
    "checksum_file": "checksum.sha256"
  }
}
EOF
    
    print_status "Metadata generated: $metadata_file"
}

# Function to create migration export from source database
create_migration_export_from_source() {
    local db_name="$1"
    local export_dir="$2"
    local compress="$3"
    
    print_status "Creating migration export from source for database: $db_name"
    
    # Generate timestamp and create export directory
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local migration_dir="${export_dir}/${timestamp}_${db_name}"
    mkdir -p "$migration_dir"
    
    # Export database with progress
    local db_file="${migration_dir}/database.sql"
    local final_file="$db_file"
    
    print_status "Exporting database from source with progress..."
    start_time=$(date +%s)
    
    # Get database size for progress estimation
    local db_size=$(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '$db_name';" 2>/dev/null | tail -n 1)
    db_size=${db_size:-0}
    
    if command -v pv &> /dev/null && [ "$db_size" -gt 0 ]; then
        # Use pv for progress if available
        if ! mysqldump -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" \
          --single-transaction \
          --routines \
          --triggers \
          "$db_name" | pv -s "${db_size}M" > "$db_file"; then
            print_error "Database export from source failed"
            return 1
        fi
    else
        # Fallback without progress bar
        if ! mysqldump -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" \
          --single-transaction \
          --routines \
          --triggers \
          "$db_name" > "$db_file"; then
            print_error "Database export from source failed"
            return 1
        fi
    fi
    
    # Always compress migration exports
    print_status "Compressing database file..."
    if command -v pv &> /dev/null; then
        pv "$db_file" | gzip > "${db_file}.gz"
    else
        gzip "$db_file"
    fi
    final_file="${db_file}.gz"
    rm -f "$db_file"  # Remove uncompressed file
    
    # Generate metadata for source export
    generate_metadata_from_source "$db_name" "$migration_dir" "$timestamp" "$compress"
    
    # Generate checksum
    print_status "Generating checksum..."
    sha256sum "$final_file" > "${migration_dir}/checksum.sha256"
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    print_status "Migration export from source completed successfully!"
    print_status "Export directory: $migration_dir"
    print_status "Database file: $(basename "$final_file")"
    print_status "Export completed in ${duration} seconds"
    print_status "Size: $(du -h "$migration_dir" | cut -f1)"
    
    return 0
}

# Function to generate metadata for source database export
generate_metadata_from_source() {
    local db_name="$1"
    local export_dir="$2"
    local timestamp="$3"
    local compress="$4"
    
    # Get database information from source
    local tables_count=$(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$db_name';" 2>/dev/null | tail -n 1)
    local routines_count=$(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = '$db_name';" 2>/dev/null | tail -n 1)
    local triggers_count=$(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = '$db_name';" 2>/dev/null | tail -n 1)
    local db_size=$(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '$db_name';" 2>/dev/null | tail -n 1)
    
    # Create metadata JSON
    local metadata_file="${export_dir}/metadata.json"
    cat > "$metadata_file" << EOF
{
  "export_info": {
    "timestamp": "$(date -Iseconds)",
    "source_host": "localhost:3306",
    "source_user": "$SOURCE_MYSQL_USER",
    "export_tool": "database-export.sh",
    "export_type": "migration"
  },
  "database_info": {
    "original_name": "$db_name",
    "size_mb": ${db_size:-0},
    "tables_count": ${tables_count:-0},
    "routines_count": ${routines_count:-0},
    "triggers_count": ${triggers_count:-0}
  },
  "export_options": {
    "compressed": true,
    "include_routines": true,
    "include_triggers": true,
    "single_transaction": true
  },
  "files": {
    "database_file": "database.sql.gz",
    "metadata_file": "metadata.json",
    "checksum_file": "checksum.sha256"
  }
}
EOF
    
    print_status "Metadata generated: $metadata_file"
}

# Function to create migration export
create_migration_export() {
    local db_name="$1"
    local export_dir="$2"
    local compress="$3"
    
    print_status "Creating migration export for database: $db_name"
    
    # Generate timestamp and create export directory
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local migration_dir="${export_dir}/${timestamp}_${db_name}"
    mkdir -p "$migration_dir"
    
    # Export database with progress
    local db_file="${migration_dir}/database.sql"
    local final_file="$db_file"
    
    print_status "Exporting database with progress..."
    start_time=$(date +%s)
    
    # Get database size for progress estimation
    local db_size=$(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '$db_name';" 2>/dev/null | tail -n 1)
    db_size=${db_size:-0}
    
    if command -v pv &> /dev/null && [ "$db_size" -gt 0 ]; then
        # Use pv for progress if available
        if ! docker compose exec -T mariadb mariadb-dump \
          -u root -p"${MYSQL_ROOT_PASSWORD}" \
          --single-transaction \
          --routines \
          --triggers \
          "$db_name" | pv -s "${db_size}M" > "$db_file"; then
            print_error "Database export failed"
            return 1
        fi
    else
        # Fallback without progress bar
        if ! docker compose exec -T mariadb mariadb-dump \
          -u root -p"${MYSQL_ROOT_PASSWORD}" \
          --single-transaction \
          --routines \
          --triggers \
          "$db_name" > "$db_file"; then
            print_error "Database export failed"
            return 1
        fi
    fi
    
    # Always compress migration exports
    print_status "Compressing database file..."
    if command -v pv &> /dev/null; then
        pv "$db_file" | gzip > "${db_file}.gz"
    else
        gzip "$db_file"
    fi
    final_file="${db_file}.gz"
    rm -f "$db_file"  # Remove uncompressed file
    
    # Generate metadata
    generate_metadata "$db_name" "$migration_dir" "$timestamp" "$compress"
    
    # Generate checksum
    print_status "Generating checksum..."
    sha256sum "$final_file" > "${migration_dir}/checksum.sha256"
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    print_status "Migration export completed successfully!"
    print_status "Export directory: $migration_dir"
    print_status "Database file: $(basename "$final_file")"
    print_status "Export completed in ${duration} seconds"
    print_status "Size: $(du -h "$migration_dir" | cut -f1)"
    
    return 0
}

# Function to export single database
export_single_database() {
    local db_name="$1"
    local export_dir="$2"
    local compress="$3"
    
    print_status "Exporting database: $db_name"
    
    # Create export directory
    mkdir -p "$export_dir"
    
    # Generate filename
    timestamp=$(date +%Y%m%d_%H%M%S)
    if [ "$compress" = "true" ]; then
        filename="${export_dir}/${db_name}_${timestamp}.sql.gz"
        docker compose exec -T mariadb mariadb-dump \
          -u root -p"${MYSQL_ROOT_PASSWORD}" \
          --single-transaction \
          --routines \
          --triggers \
          "$db_name" | gzip > "$filename"
    else
        filename="${export_dir}/${db_name}_${timestamp}.sql"
        docker compose exec -T mariadb mariadb-dump \
          -u root -p"${MYSQL_ROOT_PASSWORD}" \
          --single-transaction \
          --routines \
          --triggers \
          "$db_name" > "$filename"
    fi
    
    if [ $? -eq 0 ]; then
        print_status "Database exported successfully: $filename"
        echo "Size: $(du -h "$filename" | cut -f1)"
    else
        print_error "Export failed for database: $db_name"
        return 1
    fi
}

# Function to export all databases
export_all_databases() {
    local export_dir="$1"
    local compress="$2"
    
    print_status "Exporting all databases..."
    
    for db in "${CONTAINER_DBS[@]}"; do
        export_single_database "$db" "$export_dir" "$compress"
    done
    
    print_status "All databases exported!"
}

# Function to create migration exports for all databases
create_migration_exports_all() {
    local export_dir="$1"
    local compress="$2"
    
    print_status "Creating migration exports for all databases..."
    
    local total_dbs=${#CONTAINER_DBS[@]}
    local current_db=0
    
    for db in "${CONTAINER_DBS[@]}"; do
        ((current_db++))
        print_status "Processing database $current_db/$total_dbs: $db"
        create_migration_export "$db" "$export_dir" "$compress"
    done
    
    print_status "All migration exports completed!"
}

# Function to list migration exports
list_migration_exports() {
    local exports_dir="./migrations/exports"
    
    if [ ! -d "$exports_dir" ] || [ -z "$(ls -A "$exports_dir" 2>/dev/null)" ]; then
        print_warning "No migration exports found in $exports_dir"
        return 0
    fi
    
    echo ""
    print_status "Available migration exports:"
    echo "=================================="
    
    for export_dir in "$exports_dir"/*; do
        if [ -d "$export_dir" ]; then
            local export_name=$(basename "$export_dir")
            local metadata_file="$export_dir/metadata.json"
            
            if [ -f "$metadata_file" ]; then
                # Extract database name from metadata
                local db_name=$(grep '"original_name"' "$metadata_file" | cut -d'"' -f4)
                local timestamp=$(grep '"timestamp"' "$metadata_file" | cut -d'"' -f4 | cut -d'T' -f1)
                local size_mb=$(grep '"size_mb"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
                local tables_count=$(grep '"tables_count"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
                local compressed=$(grep '"compressed"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
                
                echo "  📁 $export_name"
                echo "     Database: $db_name"
                echo "     Date: $timestamp"
                echo "     Size: ${size_mb}MB"
                echo "     Tables: $tables_count"
                echo "     Compressed: $compressed"
                echo "     Directory: $export_dir"
                echo ""
            else
                echo "  📁 $export_name (no metadata)"
                echo ""
            fi
        fi
    done
}

# Function to show export options
show_export_menu() {
    echo ""
    echo "Export Options:"
    echo "1. Export single database"
    echo "2. Export all databases"
    echo "3. Create migration export (single database)"
    echo "4. Create migration export (all databases)"
    echo "5. Create migration export from source (single database)"
    echo "6. List available databases"
    echo "7. List migration exports"
    echo "8. Exit"
    echo ""
}

# Main script
main() {
    print_header
    
    # Check if container is running
    check_container
    
    # Check if pv is installed for progress bars
    check_pv_installation
    
    # Load environment variables
    if [ -f .env ]; then
        set -a
        source .env
        set +a
    else
        print_error ".env file not found. Please run setup.sh first."
        exit 1
    fi
    
    # Get databases from container
    get_container_databases
    
    # Get databases from source (optional)
    get_source_databases
    
    if [ ${#CONTAINER_DBS[@]} -eq 0 ] && [ ${#SOURCE_DBS[@]} -eq 0 ]; then
        print_warning "No user databases found in container or source"
        exit 0
    fi
    
    # Main menu loop
    while true; do
        show_export_menu
        read -p "Select option (1-8): " CHOICE
        
        case $CHOICE in
            1)
                echo ""
                echo "Available databases:"
                for i in "${!CONTAINER_DBS[@]}"; do
                    echo "  $((i+1)). ${CONTAINER_DBS[$i]}"
                done
                
                read -p "Select database (number): " DB_CHOICE
                
                if [[ ! "$DB_CHOICE" =~ ^[0-9]+$ ]] || [ "$DB_CHOICE" -lt 1 ] || [ "$DB_CHOICE" -gt ${#CONTAINER_DBS[@]} ]; then
                    print_error "Invalid selection"
                    continue
                fi
                
                SELECTED_DB="${CONTAINER_DBS[$((DB_CHOICE-1))]}"
                
                read -p "Export directory (default: ./exports): " EXPORT_DIR
                EXPORT_DIR=${EXPORT_DIR:-./exports}
                
                read -p "Compress export? (y/N): " COMPRESS_CHOICE
                COMPRESS=${COMPRESS_CHOICE:-false}
                if [[ "$COMPRESS" =~ ^[Yy]$ ]]; then
                    COMPRESS="true"
                else
                    COMPRESS="false"
                fi
                
                export_single_database "$SELECTED_DB" "$EXPORT_DIR" "$COMPRESS"
                ;;
            2)
                read -p "Export directory (default: ./exports): " EXPORT_DIR
                EXPORT_DIR=${EXPORT_DIR:-./exports}
                
                read -p "Compress exports? (y/N): " COMPRESS_CHOICE
                COMPRESS=${COMPRESS_CHOICE:-false}
                if [[ "$COMPRESS" =~ ^[Yy]$ ]]; then
                    COMPRESS="true"
                else
                    COMPRESS="false"
                fi
                
                export_all_databases "$EXPORT_DIR" "$COMPRESS"
                ;;
            3)
                echo ""
                echo "Available databases:"
                for i in "${!CONTAINER_DBS[@]}"; do
                    echo "  $((i+1)). ${CONTAINER_DBS[$i]}"
                done
                
                read -p "Select database (number): " DB_CHOICE
                
                if [[ ! "$DB_CHOICE" =~ ^[0-9]+$ ]] || [ "$DB_CHOICE" -lt 1 ] || [ "$DB_CHOICE" -gt ${#CONTAINER_DBS[@]} ]; then
                    print_error "Invalid selection"
                    continue
                fi
                
                SELECTED_DB="${CONTAINER_DBS[$((DB_CHOICE-1))]}"
                
                read -p "Migration export directory (default: ./migrations/exports): " EXPORT_DIR
                EXPORT_DIR=${EXPORT_DIR:-./migrations/exports}
                
                # Migration exports are always compressed
                COMPRESS="true"
                print_status "Migration exports are always compressed for space efficiency"
                
                create_migration_export "$SELECTED_DB" "$EXPORT_DIR" "$COMPRESS"
                ;;
            4)
                read -p "Migration export directory (default: ./migrations/exports): " EXPORT_DIR
                EXPORT_DIR=${EXPORT_DIR:-./migrations/exports}
                
                # Migration exports are always compressed
                COMPRESS="true"
                print_status "Migration exports are always compressed for space efficiency"
                
                create_migration_exports_all "$EXPORT_DIR" "$COMPRESS"
                ;;
            5)
                if [ ${#SOURCE_DBS[@]} -eq 0 ]; then
                    print_error "No source databases available"
                    continue
                fi
                
                echo ""
                echo "Available source databases:"
                for i in "${!SOURCE_DBS[@]}"; do
                    echo "  $((i+1)). ${SOURCE_DBS[$i]}"
                done
                
                read -p "Select source database (number): " DB_CHOICE
                
                if [[ ! "$DB_CHOICE" =~ ^[0-9]+$ ]] || [ "$DB_CHOICE" -lt 1 ] || [ "$DB_CHOICE" -gt ${#SOURCE_DBS[@]} ]; then
                    print_error "Invalid selection"
                    continue
                fi
                
                SELECTED_DB="${SOURCE_DBS[$((DB_CHOICE-1))]}"
                
                read -p "Migration export directory (default: ./migrations/exports): " EXPORT_DIR
                EXPORT_DIR=${EXPORT_DIR:-./migrations/exports}
                
                # Migration exports are always compressed
                COMPRESS="true"
                print_status "Migration exports are always compressed for space efficiency"
                
                create_migration_export_from_source "$SELECTED_DB" "$EXPORT_DIR" "$COMPRESS"
                ;;
            6)
                echo ""
                print_status "Available databases in container:"
                for db in "${CONTAINER_DBS[@]}"; do
                    echo "  - $db"
                done
                
                if [ ${#SOURCE_DBS[@]} -gt 0 ]; then
                    echo ""
                    print_status "Available databases in source:"
                    for db in "${SOURCE_DBS[@]}"; do
                        echo "  - $db"
                    done
                fi
                ;;
            7)
                list_migration_exports
                ;;
            8)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
