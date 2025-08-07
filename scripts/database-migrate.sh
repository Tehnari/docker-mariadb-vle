#!/bin/bash

# Copyright (c) 2025 Constantin Sclifos - sclifcon@gmail.com
# Licensed under MIT License
# Interactive Database Migration Script
# Helps migrate/copy specific databases using direct database connections

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
    echo -e "${BLUE}  Database Migration Tool${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to show progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local operation="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${BLUE}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "${BLUE}]${NC} %3d%% %s (%d/%d)" "$percentage" "$operation" "$current" "$total"
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Function to show file transfer progress
show_transfer_progress() {
    local file_size="$1"
    local operation="$2"
    
    if [ "$PV_AVAILABLE" = true ]; then
        # Use pv for progress if available
        return 0
    else
        # Fallback to simple progress
        print_status "$operation started... (file size: ${file_size}MB)"
        return 1
    fi
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

# Function to validate environment variables
validate_environment() {
    local missing_vars=()
    
    # Check required environment variables
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        missing_vars+=("MYSQL_ROOT_PASSWORD")
    fi
    
    if [ -z "$SOURCE_MYSQL_USER" ]; then
        missing_vars+=("SOURCE_MYSQL_USER")
    fi
    
    if [ -z "$SOURCE_MYSQL_PASSWORD" ]; then
        missing_vars+=("SOURCE_MYSQL_PASSWORD")
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo "Please check your .env file and ensure all variables are set."
        exit 1
    fi
    
    print_status "Environment variables validated"
}

# Function to check if container is running and ready
check_container() {
    if ! docker compose ps mariadb | tr '\n' ' ' | grep -q "Up"; then
        print_error "MariaDB container is not running!"
        echo "Please start the container first:"
        echo "  docker compose up -d"
        exit 1
    fi
    
    # Wait for container to be ready
    print_status "Waiting for MariaDB container to be ready..."
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" &>/dev/null; then
            print_status "✓ MariaDB container is ready!"
            return 0
        fi
        
        print_status "Waiting for MariaDB to be ready... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    print_error "MariaDB container is not responding after $max_attempts attempts"
    print_error "Please check container logs: docker compose logs mariadb"
    exit 1
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
                if [[ "$line" != "Database" && "$line" != "information_schema" && "$line" != "performance_schema" && "$line" != "mysql" ]]; then
                    SOURCE_DBS+=("$line")
                fi
            done < <(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql")
        else
            print_warning "Source database credentials not provided"
            read -p "Enter source MySQL username: " SOURCE_MYSQL_USER
            read -s -p "Enter source MySQL password: " SOURCE_MYSQL_PASSWORD
            echo ""
            
            while IFS= read -r line; do
                if [[ "$line" != "Database" && "$line" != "information_schema" && "$line" != "performance_schema" && "$line" != "mysql" ]]; then
                    SOURCE_DBS+=("$line")
                fi
            done < <(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql")
        fi
    else
        print_error "MySQL client not found. Please install mysql-client or mariadb-client"
        exit 1
    fi
    
    if [ ${#SOURCE_DBS[@]} -eq 0 ]; then
        print_warning "No databases found on source or connection failed"
        echo "Please check your source database connection"
    fi
}

# Function to get databases from container
get_container_databases() {
    print_status "Getting databases from container..."
    
    CONTAINER_DBS=()
    while IFS= read -r line; do
        if [[ "$line" != "Database" && "$line" != "information_schema" && "$line" != "performance_schema" && "$line" != "mysql" ]]; then
            CONTAINER_DBS+=("$line")
        fi
    done < <(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql")
}

# Function to migrate single database
migrate_single_database() {
    local source_db="$1"
    local target_db="$2"
    
    print_status "Migrating database: $source_db -> $target_db"
    
    # Test source database connection first
    if ! mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "USE \`$source_db\`;" 2>/dev/null; then
        print_error "Cannot connect to source database: $source_db"
        print_error "Please check your source database credentials and connection"
        return 1
    fi
    
    # Get source database size for progress estimation
    source_size=$(mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '$source_db';" 2>/dev/null | tail -n 1)
    source_size=${source_size:-0}
    print_status "Source database size: ${source_size}MB"
    
    # Create target database
    print_status "Creating target database: $target_db"
    docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`$target_db\`;"
    
    # Export from source and import to target with progress
    print_status "Starting migration process..."
    start_time=$(date +%s)
    
    # Use mysqldump to export from source and pipe directly to container
    print_status "Starting mysqldump export..."
    
    if [ "$PV_AVAILABLE" = true ] && [ "$source_size" -gt 0 ]; then
        # Use pv for progress if available and size is valid
        if ! mysqldump -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" \
          --single-transaction \
          --routines \
          --triggers \
          --add-drop-database \
          --create-options \
          "$source_db" | pv -s "${source_size}M" | docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$target_db"; then
            print_error "mysqldump failed. Check your source database connection and permissions."
            return 1
        fi
    else
        # Fallback without progress bar
        print_status "Exporting and importing data... (this may take a while)"
        if ! mysqldump -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" \
          --single-transaction \
          --routines \
          --triggers \
          --add-drop-database \
          --create-options \
          "$source_db" | docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$target_db"; then
            print_error "mysqldump failed. Check your source database connection and permissions."
            return 1
        fi
    fi
    
    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        print_status "Database migrated successfully: $source_db -> $target_db"
        print_status "Migration completed in ${duration} seconds"
        print_status "Source database size: ${source_size}MB"
        
        # Apply permissions after successful migration
        apply_permissions_after_migration "$target_db"
    else
        print_error "Migration failed for database: $source_db"
        return 1
    fi
}

# Function to migrate all databases
migrate_all_databases() {
    print_status "Migrating all databases..."
    
    local total_dbs=${#SOURCE_DBS[@]}
    local current_db=0
    
    for db in "${SOURCE_DBS[@]}"; do
        ((current_db++))
        show_progress "$current_db" "$total_dbs" "Migrating databases"
        migrate_single_database "$db" "$db"
    done
    
    print_status "All databases migrated!"
}

# Function to drop database with double confirmation
drop_database() {
    echo ""
    print_status "Drop Database"
    echo "==============="
    
    if [ ${#CONTAINER_DBS[@]} -eq 0 ]; then
        print_error "No databases available in container"
        return 1
    fi
    
    echo "Available databases in container:"
    for i in "${!CONTAINER_DBS[@]}"; do
        echo "  $((i+1)). ${CONTAINER_DBS[$i]}"
    done
    
    read -p "Select database to drop (number): " DB_CHOICE
    
    if [[ ! "$DB_CHOICE" =~ ^[0-9]+$ ]] || [ "$DB_CHOICE" -lt 1 ] || [ "$DB_CHOICE" -gt ${#CONTAINER_DBS[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    SELECTED_DB="${CONTAINER_DBS[$((DB_CHOICE-1))]}"
    
    print_warning "⚠️  WARNING: This will permanently delete the database '$SELECTED_DB' and all its data!"
    print_warning "This action cannot be undone!"
    echo ""
    
    # First confirmation
    read -p "Are you sure you want to drop database '$SELECTED_DB'? (yes/no): " CONFIRM1
    
    if [[ ! "$CONFIRM1" =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Operation cancelled"
        return 0
    fi
    
    # Second confirmation with database name
    echo ""
    print_warning "⚠️  FINAL WARNING: You are about to permanently delete database '$SELECTED_DB'"
    read -p "Type the database name '$SELECTED_DB' to confirm: " CONFIRM2
    
    if [[ "$CONFIRM2" != "$SELECTED_DB" ]]; then
        print_error "Database name does not match. Operation cancelled."
        return 1
    fi
    
    print_status "Dropping database: $SELECTED_DB"
    
    if docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE \`$SELECTED_DB\`;"; then
        print_status "✓ Database '$SELECTED_DB' dropped successfully!"
        
        # Refresh container databases list
        get_container_databases
    else
        print_error "Failed to drop database '$SELECTED_DB'"
        return 1
    fi
}

# Function to check database permissions for a user
check_database_permissions() {
    local database="$1"
    local username="$2"
    
    print_status "Checking permissions for user '$username' on database '$database'..."
    
    # Check if user exists
    local user_exists=$(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT COUNT(*) FROM mysql.user WHERE User='$username';" 2>/dev/null | tail -n 1)
    
    if [ "$user_exists" -eq 0 ]; then
        print_warning "User '$username' does not exist in container"
        return 1
    fi
    
    # Check current permissions
    local permissions=$(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW GRANTS FOR '$username'@'%';" 2>/dev/null)
    
    if echo "$permissions" | grep -q "GRANT.*ON.*\`$database\`.*TO.*\`$username\`@\`%\`"; then
        print_status "✓ User '$username' has permissions on database '$database'"
        return 0
    else
        print_warning "User '$username' does not have permissions on database '$database'"
        print_warning "Current grants for user '$username':"
        echo "$permissions" | while read -r line; do
            echo "  $line"
        done
        return 1
    fi
}

# Function to apply correct permissions for database user
apply_database_permissions() {
    local database="$1"
    local username="$2"
    local password="$3"
    
    print_status "Applying permissions for user '$username' on database '$database'..."
    
    # Check if user exists, create if not
    local user_exists=$(docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT COUNT(*) FROM mysql.user WHERE User='$username';" 2>/dev/null | tail -n 1)
    
    if [ "$user_exists" -eq 0 ]; then
        print_status "Creating user '$username'..."
        docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER '$username'@'%' IDENTIFIED BY '$password';"
        
        if [ $? -eq 0 ]; then
            print_status "✓ User '$username' created successfully"
        else
            print_error "Failed to create user '$username'"
            return 1
        fi
    else
        print_status "User '$username' already exists"
    fi
    
    # Grant permissions on the database
    print_status "Granting permissions on database '$database'..."
    docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`$database\`.* TO '$username'@'%';"
    
    if [ $? -eq 0 ]; then
        print_status "✓ Permissions granted successfully"
    else
        print_error "Failed to grant permissions"
        return 1
    fi
    
    # Flush privileges
    print_status "Flushing privileges..."
    docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
    
    if [ $? -eq 0 ]; then
        print_status "✓ Privileges flushed successfully"
    else
        print_error "Failed to flush privileges"
        return 1
    fi
    
    print_status "✓ Database permissions applied successfully for user '$username' on database '$database'"
    return 0
}

# Function to check and apply permissions for all databases
check_and_apply_permissions() {
    echo ""
    print_status "Database Permission Management"
    echo "=================================="
    
    if [ ${#CONTAINER_DBS[@]} -eq 0 ]; then
        print_error "No databases available in container"
        return 1
    fi
    
    echo "Available databases in container:"
    for i in "${!CONTAINER_DBS[@]}"; do
        echo "  $((i+1)). ${CONTAINER_DBS[$i]}"
    done
    
    read -p "Select database to check/apply permissions (number): " DB_CHOICE
    
    if [[ ! "$DB_CHOICE" =~ ^[0-9]+$ ]] || [ "$DB_CHOICE" -lt 1 ] || [ "$DB_CHOICE" -gt ${#CONTAINER_DBS[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_db="${CONTAINER_DBS[$((DB_CHOICE-1))]}"
    
    echo ""
    echo "Permission Options:"
    echo "1. Check current permissions"
    echo "2. Apply permissions for environment user"
    echo "3. Apply permissions for custom user"
    echo "4. Back to main menu"
    echo ""
    
    read -p "Select option (1-4): " PERM_CHOICE
    
    case $PERM_CHOICE in
        1)
            # Check permissions for environment user
            if [ -n "$MYSQL_USER" ]; then
                check_database_permissions "$selected_db" "$MYSQL_USER"
            else
                print_error "MYSQL_USER not defined in environment"
            fi
            ;;
        2)
            # Apply permissions for environment user
            if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
                apply_database_permissions "$selected_db" "$MYSQL_USER" "$MYSQL_PASSWORD"
            else
                print_error "MYSQL_USER or MYSQL_PASSWORD not defined in environment"
            fi
            ;;
        3)
            # Apply permissions for custom user
            read -p "Enter username: " CUSTOM_USER
            read -s -p "Enter password: " CUSTOM_PASSWORD
            echo ""
            
            if [ -n "$CUSTOM_USER" ] && [ -n "$CUSTOM_PASSWORD" ]; then
                apply_database_permissions "$selected_db" "$CUSTOM_USER" "$CUSTOM_PASSWORD"
            else
                print_error "Username and password are required"
            fi
            ;;
        4)
            return 0
            ;;
        *)
            print_error "Invalid option"
            return 1
            ;;
    esac
}

# Function to apply permissions after successful migration
apply_permissions_after_migration() {
    local database="$1"
    
    # Only apply if environment user is defined
    if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
        print_status "Applying permissions for environment user '$MYSQL_USER' on migrated database '$database'..."
        
        if apply_database_permissions "$database" "$MYSQL_USER" "$MYSQL_PASSWORD"; then
            print_status "✓ Permissions applied successfully after migration"
        else
            print_warning "Failed to apply permissions after migration"
            print_warning "You may need to manually grant permissions for user '$MYSQL_USER'"
        fi
    else
        print_warning "MYSQL_USER or MYSQL_PASSWORD not defined - skipping permission application"
        print_warning "You may need to manually grant permissions for your application user"
    fi
}

# Function to show migration options
show_migration_menu() {
    echo ""
    echo "Migration Options:"
    echo "1. Migrate single database"
    echo "2. Migrate all databases"
    echo "3. Import SQL dump file"
    echo "4. Import from compressed backup"
    echo "5. Import from migration export"
    echo "6. List available databases"
    echo "7. List migration exports"
    echo "8. Test database connection"
    echo "9. Drop database (with double confirmation)"
    echo "10. Manage database permissions"
    echo "11. Exit"
    echo ""
}

# Function to import SQL dump
import_sql_dump() {
    echo ""
    print_status "SQL Dump Import"
    echo "=================="
    
    read -p "Enter path to SQL dump file: " SQL_FILE
    
    if [ ! -f "$SQL_FILE" ]; then
        print_error "File not found: $SQL_FILE"
        return 1
    fi
    
    read -p "Enter target database name: " TARGET_DB
    
    print_status "Creating database: $TARGET_DB"
    docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`$TARGET_DB\`;"
    
    # Get file size for progress estimation
    file_size=$(du -m "$SQL_FILE" | cut -f1)
    print_status "SQL file size: ${file_size}MB"
    
    print_status "Importing SQL dump..."
    start_time=$(date +%s)
    
    if [ "$PV_AVAILABLE" = true ] && [ "$file_size" -gt 0 ]; then
        # Use pv for progress if available and size is valid
        pv "$SQL_FILE" | docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$TARGET_DB"
    else
        # Fallback without progress bar
        docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$TARGET_DB" < "$SQL_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        print_status "SQL dump imported successfully!"
        print_status "Import completed in ${duration} seconds"
        
        # Apply permissions after successful import
        apply_permissions_after_migration "$TARGET_DB"
    else
        print_error "Import failed!"
        return 1
    fi
}

# Function to import from compressed backup
import_compressed_backup() {
    echo ""
    print_status "Compressed Backup Import"
    echo "============================"
    
    BACKUP_DIR="./backups"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]; then
        print_error "No compressed backups found in $BACKUP_DIR"
        return 1
    fi
    
    echo "Available backups:"
    ls -la "$BACKUP_DIR"/*.tar.gz | while read -r line; do
        echo "  $line"
    done
    
    read -p "Enter backup filename: " BACKUP_FILE
    
    if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
        print_error "Backup file not found: $BACKUP_FILE"
        return 1
    fi
    
    read -p "Enter target database name: " TARGET_DB
    
    print_warning "This will stop the MariaDB container during restore process"
    read -p "Continue? (y/N): " CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled"
        return 0
    fi
    
    print_status "Stopping MariaDB container..."
    docker compose stop mariadb
    
    # Get backup file size for progress estimation
    backup_size=$(du -m "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    print_status "Backup file size: ${backup_size}MB"
    
    print_status "Restoring from compressed backup..."
    start_time=$(date +%s)
    
    # Extract and restore with progress
    if [ "$PV_AVAILABLE" = true ] && [ "$backup_size" -gt 0 ]; then
        # Use pv for progress if available and size is valid
        pv "$BACKUP_DIR/$BACKUP_FILE" | gunzip | \
        docker compose exec -T mariadb mariadb-backup \
          --copy-back \
          --target-dir=/tmp/restore \
          --user=root \
          --password="${MYSQL_ROOT_PASSWORD}"
    else
        # Fallback without progress bar
        gunzip -c "$BACKUP_DIR/$BACKUP_FILE" | \
        docker compose exec -T mariadb mariadb-backup \
          --copy-back \
          --target-dir=/tmp/restore \
          --user=root \
          --password="${MYSQL_ROOT_PASSWORD}"
    fi
    
    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        print_status "Backup restored successfully!"
        print_status "Restore completed in ${duration} seconds"
    else
        print_error "Restore failed!"
        return 1
    fi
    
    print_status "Starting MariaDB container..."
    docker compose start mariadb
}

# Function to list databases
list_databases() {
    echo ""
    print_status "Database Information"
    echo "======================"
    
    # Refresh database lists before displaying
    get_source_databases
    get_container_databases
    
    echo "Databases in source (localhost:3306):"
    if [ ${#SOURCE_DBS[@]} -eq 0 ]; then
        echo "  No databases found or connection failed"
    else
        for db in "${SOURCE_DBS[@]}"; do
            echo "  - $db"
        done
    fi
    
    echo ""
    echo "Databases in container (localhost:3366):"
    if [ ${#CONTAINER_DBS[@]} -eq 0 ]; then
        echo "  No user databases found"
    else
        for db in "${CONTAINER_DBS[@]}"; do
            echo "  - $db"
        done
    fi
}

# Function to validate migration export
validate_migration_export() {
    local export_dir="$1"
    
    if [ ! -d "$export_dir" ]; then
        print_error "Migration export directory not found: $export_dir"
        return 1
    fi
    
    local metadata_file="$export_dir/metadata.json"
    local checksum_file="$export_dir/checksum.sha256"
    
    if [ ! -f "$metadata_file" ]; then
        print_error "Metadata file not found: $metadata_file"
        return 1
    fi
    
    # Check for database file
    local db_file="$export_dir/database.sql"
    local db_file_gz="$export_dir/database.sql.gz"
    
    if [ ! -f "$db_file" ] && [ ! -f "$db_file_gz" ]; then
        print_error "Database file not found in: $export_dir"
        return 1
    fi
    
    # Validate checksum if available
    if [ -f "$checksum_file" ]; then
        local actual_file=""
        if [ -f "$db_file_gz" ]; then
            actual_file="$db_file_gz"
        else
            actual_file="$db_file"
        fi
        
        # Extract just the filename from the checksum file
        local checksum_filename=$(basename "$actual_file")
        local expected_checksum=$(cat "$checksum_file" | awk '{print $1}')
        local actual_checksum=$(sha256sum "$actual_file" | awk '{print $1}')
        
        if [ "$expected_checksum" != "$actual_checksum" ]; then
            print_error "Checksum validation failed for: $actual_file"
            print_error "Expected: $expected_checksum"
            print_error "Actual:   $actual_checksum"
            return 1
        fi
        print_status "✓ Checksum validation passed"
    fi
    
    return 0
}

# Function to read migration metadata
read_migration_metadata() {
    local export_dir="$1"
    local metadata_file="$export_dir/metadata.json"
    
    if [ ! -f "$metadata_file" ]; then
        return 1
    fi
    
    # Extract metadata using grep and cut (simple JSON parsing)
    local original_name=$(grep '"original_name"' "$metadata_file" | cut -d'"' -f4)
    local size_mb=$(grep '"size_mb"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
    local tables_count=$(grep '"tables_count"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
    local routines_count=$(grep '"routines_count"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
    local triggers_count=$(grep '"triggers_count"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
    local compressed=$(grep '"compressed"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
    local timestamp=$(grep '"timestamp"' "$metadata_file" | cut -d'"' -f4)
    
    echo "Migration Export Information:"
    echo "============================"
    echo "Original Database: $original_name"
    echo "Size: ${size_mb}MB"
    echo "Tables: $tables_count"
    echo "Routines: $routines_count"
    echo "Triggers: $triggers_count"
    echo "Compressed: $compressed"
    echo "Export Date: $timestamp"
    echo ""
}

# Function to find migration exports in multiple locations
find_migration_exports() {
    local exports_dir="./migrations/exports"
    local imports_dir="./migrations/imports"
    local all_exports=()
    local export_sources=()
    
    # Check internal exports
    if [ -d "$exports_dir" ] && [ -n "$(ls -A "$exports_dir" 2>/dev/null)" ]; then
        for export_dir in "$exports_dir"/*; do
            if [ -d "$export_dir" ]; then
                local metadata_file="$export_dir/metadata.json"
                if [ -f "$metadata_file" ]; then
                    all_exports+=("$export_dir")
                    export_sources+=("internal")
                fi
            fi
        done
    fi
    
    # Check external imports
    if [ -d "$imports_dir" ] && [ -n "$(ls -A "$imports_dir" 2>/dev/null)" ]; then
        for export_dir in "$imports_dir"/*; do
            if [ -d "$export_dir" ]; then
                local metadata_file="$export_dir/metadata.json"
                if [ -f "$metadata_file" ]; then
                    all_exports+=("$export_dir")
                    export_sources+=("external")
                fi
            fi
        done
    fi
    
    echo "${all_exports[@]}"
}

# Function to import from migration export
import_migration_export() {
    echo ""
    print_status "Migration Export Import"
    echo "=========================="
    
    # Find all available migration exports
    local all_exports=($(find_migration_exports))
    local export_sources=()
    
    # Rebuild sources array
    local exports_dir="./migrations/exports"
    local imports_dir="./migrations/imports"
    
    if [ -d "$exports_dir" ] && [ -n "$(ls -A "$exports_dir" 2>/dev/null)" ]; then
        for export_dir in "$exports_dir"/*; do
            if [ -d "$export_dir" ]; then
                local metadata_file="$export_dir/metadata.json"
                if [ -f "$metadata_file" ]; then
                    export_sources+=("internal")
                fi
            fi
        done
    fi
    
    if [ -d "$imports_dir" ] && [ -n "$(ls -A "$imports_dir" 2>/dev/null)" ]; then
        for export_dir in "$imports_dir"/*; do
            if [ -d "$export_dir" ]; then
                local metadata_file="$export_dir/metadata.json"
                if [ -f "$metadata_file" ]; then
                    export_sources+=("external")
                fi
            fi
        done
    fi
    
    if [ ${#all_exports[@]} -eq 0 ]; then
        print_error "No migration exports found"
        print_status "Available locations:"
        print_status "  - Internal exports: ./migrations/exports/"
        print_status "  - External imports: ./migrations/imports/"
        print_status ""
        print_status "To import external migrations:"
        print_status "  1. Copy migration folder to ./migrations/imports/"
        print_status "  2. Ensure it contains: metadata.json, database.sql.gz, checksum.sha256"
        return 1
    fi
    
    echo "Available migration exports:"
    echo "============================"
    
    local i=1
    for idx in "${!all_exports[@]}"; do
        local export_dir="${all_exports[$idx]}"
        local source_type="${export_sources[$idx]}"
        local export_name=$(basename "$export_dir")
        local metadata_file="$export_dir/metadata.json"
        
        if [ -f "$metadata_file" ]; then
            local db_name=$(grep '"original_name"' "$metadata_file" | cut -d'"' -f4)
            local timestamp=$(grep '"timestamp"' "$metadata_file" | cut -d'"' -f4 | cut -d'T' -f1)
            local size_mb=$(grep '"size_mb"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
            local source_host=$(grep '"source_host"' "$metadata_file" | cut -d'"' -f4)
            
            echo "  $i. $export_name"
            echo "     Source: $source_type ($source_host)"
            echo "     Database: $db_name"
            echo "     Date: $timestamp"
            echo "     Size: ${size_mb}MB"
            echo ""
            
            ((i++))
        fi
    done
    
    read -p "Select migration export (number): " EXPORT_CHOICE
    
    if [[ ! "$EXPORT_CHOICE" =~ ^[0-9]+$ ]] || [ "$EXPORT_CHOICE" -lt 1 ] || [ "$EXPORT_CHOICE" -gt ${#all_exports[@]} ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_export="${all_exports[$((EXPORT_CHOICE-1))]}"
    local selected_source="${export_sources[$((EXPORT_CHOICE-1))]}"
    
    # Validate the migration export
    if ! validate_migration_export "$selected_export"; then
        print_error "Invalid migration export"
        return 1
    fi
    
    # Display metadata
    read_migration_metadata "$selected_export"
    
    # Get target database name
    local original_name=$(grep '"original_name"' "$selected_export/metadata.json" | cut -d'"' -f4)
    read -p "Enter target database name (or press Enter to use original name '$original_name'): " TARGET_DB
    TARGET_DB=${TARGET_DB:-$original_name}
    
    # Check if database already exists
    if docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE \`$TARGET_DB\`;" 2>/dev/null; then
        print_warning "Database '$TARGET_DB' already exists!"
        read -p "Do you want to drop and recreate it? (y/N): " DROP_CONFIRM
        
        if [[ "$DROP_CONFIRM" =~ ^[Yy]$ ]]; then
            print_status "Dropping existing database: $TARGET_DB"
            docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE \`$TARGET_DB\`;"
        else
            print_status "Import cancelled"
            return 0
        fi
    fi
    
    # Create target database
    print_status "Creating target database: $TARGET_DB"
    docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE \`$TARGET_DB\`;"
    
    # Determine database file
    local db_file="$selected_export/database.sql"
    local db_file_gz="$selected_export/database.sql.gz"
    local actual_file=""
    
    if [ -f "$db_file_gz" ]; then
        actual_file="$db_file_gz"
    else
        actual_file="$db_file"
    fi
    
    # Import with progress
    print_status "Importing migration export..."
    start_time=$(date +%s)
    
    if [ "$PV_AVAILABLE" = true ]; then
        # Use pv for progress if available
        if [[ "$actual_file" == *.gz ]]; then
            pv "$actual_file" | gunzip | docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$TARGET_DB"
        else
            pv "$actual_file" | docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$TARGET_DB"
        fi
    else
        # Fallback without progress bar
        if [[ "$actual_file" == *.gz ]]; then
            gunzip -c "$actual_file" | docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$TARGET_DB"
        else
            docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$TARGET_DB" < "$actual_file"
        fi
    fi
    
    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        print_status "Migration import completed successfully!"
        print_status "Database '$TARGET_DB' imported in ${duration} seconds"
        
        # Apply permissions after successful import
        apply_permissions_after_migration "$TARGET_DB"
        
        # Refresh container database list
        get_container_databases
    else
        print_error "Migration import failed!"
        return 1
    fi
}

# Function to list migration exports
list_migration_exports() {
    local exports_dir="./migrations/exports"
    local imports_dir="./migrations/imports"
    
    local found_exports=false
    
    echo ""
    print_status "Available migration exports:"
    echo "=================================="
    
    # List internal exports
    if [ -d "$exports_dir" ] && [ -n "$(ls -A "$exports_dir" 2>/dev/null)" ]; then
        echo "📂 Internal Exports (./migrations/exports/):"
        echo "----------------------------------------"
        
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
                    local source_host=$(grep '"source_host"' "$metadata_file" | cut -d'"' -f4)
                    
                    echo "  📁 $export_name"
                    echo "     Database: $db_name"
                    echo "     Source: $source_host"
                    echo "     Date: $timestamp"
                    echo "     Size: ${size_mb}MB"
                    echo "     Tables: $tables_count"
                    echo "     Directory: $export_dir"
                    echo ""
                    found_exports=true
                else
                    echo "  📁 $export_name (no metadata)"
                    echo ""
                fi
            fi
        done
    fi
    
    # List external imports
    if [ -d "$imports_dir" ] && [ -n "$(ls -A "$imports_dir" 2>/dev/null)" ]; then
        echo "📂 External Imports (./migrations/imports/):"
        echo "----------------------------------------"
        
        for export_dir in "$imports_dir"/*; do
            if [ -d "$export_dir" ]; then
                local export_name=$(basename "$export_dir")
                local metadata_file="$export_dir/metadata.json"
                
                if [ -f "$metadata_file" ]; then
                    # Extract database name from metadata
                    local db_name=$(grep '"original_name"' "$metadata_file" | cut -d'"' -f4)
                    local timestamp=$(grep '"timestamp"' "$metadata_file" | cut -d'"' -f4 | cut -d'T' -f1)
                    local size_mb=$(grep '"size_mb"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
                    local tables_count=$(grep '"tables_count"' "$metadata_file" | cut -d':' -f2 | tr -d ' ,')
                    local source_host=$(grep '"source_host"' "$metadata_file" | cut -d'"' -f4)
                    
                    echo "  📁 $export_name"
                    echo "     Database: $db_name"
                    echo "     Source: $source_host"
                    echo "     Date: $timestamp"
                    echo "     Size: ${size_mb}MB"
                    echo "     Tables: $tables_count"
                    echo "     Directory: $export_dir"
                    echo ""
                    found_exports=true
                else
                    echo "  📁 $export_name (no metadata)"
                    echo ""
                fi
            fi
        done
    fi
    
    if [ "$found_exports" = false ]; then
        print_warning "No migration exports found"
        echo ""
        print_status "Available locations:"
        print_status "  - Internal exports: ./migrations/exports/"
        print_status "  - External imports: ./migrations/imports/"
        echo ""
        print_status "To import external migrations:"
        print_status "  1. Copy migration folder to ./migrations/imports/"
        print_status "  2. Ensure it contains: metadata.json, database.sql.gz, checksum.sha256"
    fi
}

# Function to test database connection
test_connection() {
    echo ""
    print_status "Testing Database Connections"
    echo "================================"
    
    # Test source connection
    print_status "Testing source connection (localhost:3306)..."
    if mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "SELECT 1;" &>/dev/null; then
        print_status "✓ Source connection successful"
    else
        print_error "✗ Source connection failed"
    fi
    
    # Test container connection
    print_status "Testing container connection..."
    if docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" &>/dev/null; then
        print_status "✓ Container connection successful"
    else
        print_error "✗ Container connection failed"
    fi
}

# Main script
main() {
    print_header
    
    # Load environment variables first
    if [ -f .env ]; then
        set -a
        source .env
        set +a
    else
        print_error ".env file not found. Please run setup.sh first."
        exit 1
    fi
    
    # Validate environment variables
    validate_environment
    
    # Check if pv is installed for progress bars
    check_pv_installation
    
    # Check if container is running
    check_container
    
    # Get databases from source and container
    get_source_databases
    get_container_databases
    
    # Main menu loop
    while true; do
        show_migration_menu
        read -p "Select option (1-11): " CHOICE
        
        case $CHOICE in
            1)
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
                
                read -p "Enter target database name (or press Enter to use same name): " TARGET_DB
                TARGET_DB=${TARGET_DB:-$SELECTED_DB}
                
                migrate_single_database "$SELECTED_DB" "$TARGET_DB"
                ;;
            2)
                if [ ${#SOURCE_DBS[@]} -eq 0 ]; then
                    print_error "No source databases available"
                    continue
                fi
                
                print_warning "This will migrate all databases from source to container"
                read -p "Continue? (y/N): " CONFIRM
                
                if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                    migrate_all_databases
                else
                    print_status "Operation cancelled"
                fi
                ;;
            3)
                import_sql_dump
                ;;
            4)
                import_compressed_backup
                ;;
            5)
                import_migration_export
                ;;
            6)
                list_databases
                ;;
            7)
                list_migration_exports
                ;;
            8)
                test_connection
                ;;
            9)
                drop_database
                ;;
            10)
                check_and_apply_permissions
                ;;
            11)
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
