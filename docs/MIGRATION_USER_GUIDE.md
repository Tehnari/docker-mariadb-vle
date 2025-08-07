# Database Migration System - User Guide

## 📋 Table of Contents
1. [Quick Start](#quick-start)
2. [Understanding Migration Types](#understanding-migration-types)
3. [Export Scenarios](#export-scenarios)
4. [Import Scenarios](#import-scenarios)
5. [Cross-Platform Migration](#cross-platform-migration)
6. [Advanced Workflows](#advanced-workflows)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- MariaDB client tools (`mariadb-client` or `mysql-client`)
- Optional: `pv` for progress bars (`sudo apt install pv`)

### Basic Workflow
```bash
# 1. Export a database for migration
./scripts/database-export.sh
# Choose option 3: Create migration export (single database)

# 2. Import the migration export
./scripts/database-migrate.sh
# Choose option 5: Import from migration export
```

### Source Database Availability
The migration script automatically checks source database availability:

**✅ Source Available:**
- All migration options enabled
- Direct database migration possible

**⚠️ Source Not Available:**
- Clear warning displayed
- Source-dependent options disabled
- Import and management features still work
- Helpful troubleshooting guidance provided

## 📊 Understanding Migration Types

### Migration Exports vs Standard Exports

| Feature | Migration Export | Standard Export |
|---------|------------------|-----------------|
| **Metadata** | ✅ JSON metadata with database info | ❌ No metadata |
| **Compression** | ✅ Always compressed | ⚠️ Optional |
| **Progress Bars** | ✅ Real-time progress | ✅ Real-time progress |
| **Checksums** | ✅ SHA256 validation | ❌ No validation |
| **Cross-Platform** | ✅ Designed for portability | ❌ Server-specific |
| **Target Naming** | ✅ Custom target names | ❌ Original names only |

### Folder Structure
```
migrations/
├── exports/          # Internal migration exports
│   └── YYYYMMDD_HHMMSS_dbname/
│       ├── metadata.json      # Export information
│       ├── database.sql.gz    # Compressed database dump
│       └── checksum.sha256    # Data integrity check
└── imports/          # External migration imports
    └── (external migration packages)
```

## 📤 Export Scenarios

### Scenario 1: Export from Container Database
**Use Case**: Export a database that's running in the Docker container

```bash
./scripts/database-export.sh
# Choose option 3: Create migration export (single database)
# Select database from container list
# Result: ./migrations/exports/20241201_143000_dbname/
```

**What happens:**
- Creates timestamped directory
- Exports database with `mariadb-dump`
- Compresses with `gzip`
- Generates metadata and checksum
- Shows progress bar

### Scenario 2: Export from Source Database
**Use Case**: Export from external database (localhost:3306)

```bash
./scripts/database-export.sh
# Choose option 5: Create migration export from source
# Enter source database credentials if needed
# Select database from source list
# Result: ./migrations/exports/20241201_143000_dbname/
```

**What happens:**
- Connects to external database
- Uses `mysqldump` for export
- Same compression and metadata as container export
- Source host recorded as `localhost:3306`

### Scenario 3: Export All Databases
**Use Case**: Create migration exports for all databases

```bash
./scripts/database-export.sh
# Choose option 4: Create migration export (all databases)
# Creates separate export for each database
```

**What happens:**
- Exports each database individually
- Creates separate directory for each
- All exports compressed and validated

## 📥 Import Scenarios

### Scenario 1: Import to Container
**Use Case**: Import migration export to Docker container

```bash
./scripts/database-migrate.sh
# Choose option 5: Import from migration export
# Select migration export from list
# Enter target database name (or use original)
# Confirm if database exists
```

**What happens:**
- Validates migration export
- Shows metadata information
- Creates target database
- Imports with progress bar
- Refreshes database list automatically

### Scenario 2: Import with Custom Name
**Use Case**: Import database with different name

```bash
./scripts/database-migrate.sh
# Choose option 5: Import from migration export
# Select migration export
# Enter custom target name (e.g., "gallery2_prod")
# Database imported as "gallery2_prod"
```

### Scenario 3: Import with Existing Database
**Use Case**: Import when target database already exists

```bash
./scripts/database-migrate.sh
# Choose option 5: Import from migration export
# Select migration export
# Enter target name
# Choose: Drop and recreate (y) or Cancel (N)
```

## 🌐 Cross-Platform Migration

### Scenario 1: Server-to-Server Migration
**Use Case**: Move database from Server A to Server B

**On Server A (Source):**
```bash
# 1. Export database
./scripts/database-export.sh
# Choose option 3: Create migration export
# Select database to export

# 2. Copy migration folder to Server B
scp -r ./migrations/exports/20241201_143000_dbname/ user@server-b:/path/to/migrations/imports/
```

**On Server B (Target):**
```bash
# 1. Place migration folder in imports directory
mkdir -p ./migrations/imports/
# Copy migration folder to ./migrations/imports/

# 2. Import the migration
./scripts/database-migrate.sh
# Choose option 5: Import from migration export
# Select the imported migration
# Enter target database name
```

### Scenario 2: Development to Production
**Use Case**: Deploy database from development to production

**Development Server:**
```bash
# 1. Export development database
./scripts/database-export.sh
# Choose option 3: Create migration export
# Select development database

# 2. Transfer to production
rsync -av ./migrations/exports/20241201_143000_devdb/ prod-server:/path/to/migrations/imports/
```

**Production Server:**
```bash
# 1. Import with production name
./scripts/database-migrate.sh
# Choose option 5: Import from migration export
# Select imported migration
# Enter production database name (e.g., "prod_db")
```

### Scenario 3: Backup and Restore
**Use Case**: Create backup for disaster recovery

**Create Backup:**
```bash
# 1. Export critical databases
./scripts/database-export.sh
# Choose option 4: Create migration export (all databases)

# 2. Archive migration exports
tar -czf backup_$(date +%Y%m%d).tar.gz ./migrations/exports/
```

**Restore from Backup:**
```bash
# 1. Extract backup
tar -xzf backup_20241201.tar.gz

# 2. Import each database
./scripts/database-migrate.sh
# Choose option 5: Import from migration export
# Select each migration export
```

## 🔧 Advanced Workflows

### Workflow 1: Database Migration with Validation
```bash
# 1. Export with validation
./scripts/database-export.sh
# Create migration export
# Verify checksum file exists

# 2. Transfer with integrity check
scp -r ./migrations/exports/20241201_143000_dbname/ target-server:/path/to/imports/

# 3. Import with validation
./scripts/database-migrate.sh
# Import migration export
# Script automatically validates checksum
```

### Workflow 2: Multiple Database Migration
```bash
# 1. Export all databases
./scripts/database-export.sh
# Choose option 4: Create migration export (all databases)

# 2. Transfer all exports
rsync -av ./migrations/exports/ target-server:/path/to/imports/

# 3. Import all databases
./scripts/database-migrate.sh
# Repeat option 5 for each migration export
```

### Workflow 3: Database Cloning
```bash
# 1. Export source database
./scripts/database-export.sh
# Create migration export for source_db

# 2. Import as clone
./scripts/database-migrate.sh
# Import migration export
# Enter target name: source_db_clone
```

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### Issue 1: "No migration exports found"
**Symptoms**: Script shows no available migration exports
**Solutions**:
```bash
# Check if exports exist
ls -la ./migrations/exports/

# Create new migration export
./scripts/database-export.sh
# Choose option 3 or 4
```

#### Issue 2: "Checksum validation failed"
**Symptoms**: Import fails with checksum error
**Solutions**:
```bash
# Re-export the database
./scripts/database-export.sh
# Create new migration export

# Or manually verify checksum
sha256sum -c ./migrations/exports/YYYYMMDD_HHMMSS_dbname/checksum.sha256
```

#### Issue 3: "Database already exists"
**Symptoms**: Import fails because target database exists
**Solutions**:
```bash
# Use the interactive drop database feature:
./scripts/database-migrate.sh
# Choose option 9: Drop database (with double confirmation)

# Or manually drop database first:
docker compose exec mariadb mariadb -u root -p"password" -e "DROP DATABASE dbname;"
```

#### Issue 4: "Progress bar not showing"
**Symptoms**: No progress indication during import/export
**Solutions**:
```bash
# The script now automatically checks for pv and provides installation guidance
# If you see a warning about pv not being installed, follow the instructions shown

# Manual installation if needed:
# Ubuntu/Debian: sudo apt-get install pv
# CentOS/RHEL: sudo yum install pv
# macOS: brew install pv

# Or use without progress (script works fine)
```

#### Issue 5: "Permission denied"
**Symptoms**: Cannot access migration directories
**Solutions**:
```bash
# Fix permissions
chmod 755 ./migrations/
chmod 755 ./migrations/exports/
chmod 755 ./migrations/imports/

# Check script permissions
chmod +x ./scripts/database-export.sh
chmod +x ./scripts/database-migrate.sh
```

### Debugging Commands

#### Check Migration Exports
```bash
# List all migration exports
ls -la ./migrations/exports/

# View metadata
cat ./migrations/exports/YYYYMMDD_HHMMSS_dbname/metadata.json

# Verify checksum
sha256sum -c ./migrations/exports/YYYYMMDD_HHMMSS_dbname/checksum.sha256
```

#### Check Database Status
```bash
# List container databases
docker compose exec mariadb mariadb -u root -p"password" -e "SHOW DATABASES;"

# Test database connection
./scripts/database-migrate.sh
# Choose option 8: Test database connection
```

#### Enable Debug Mode
```bash
# Run with debug output
bash -x ./scripts/database-export.sh
bash -x ./scripts/database-migrate.sh
```

## 📋 Best Practices

### 1. Naming Conventions
- **Migration exports**: Use descriptive names in target database
- **Timestamps**: Always use timestamped directories
- **Metadata**: Keep metadata files for documentation

### 2. File Organization
```
migrations/
├── exports/          # Your own exports
│   ├── 20241201_143000_prod_db/
│   └── 20241201_143000_dev_db/
└── imports/          # External imports
    ├── 20241201_143000_external_db/
    └── backup_20241201/
```

### 3. Validation Steps
- ✅ Always verify checksums before transfer
- ✅ Test imports on non-production systems
- ✅ Keep migration exports organized
- ✅ Document database names and purposes

### 4. Security Considerations
- 🔒 Use secure transfer methods (scp, rsync with SSH)
- 🔒 Validate migration exports before import
- 🔒 Use strong database passwords
- 🔒 Limit access to migration directories

### 5. Performance Tips
- ⚡ Use compression for large databases
- ⚡ Transfer during low-traffic periods
- ⚡ Monitor disk space during exports
- ⚡ Use progress bars for visibility

### 6. Backup Strategy
- 📦 Create regular migration exports
- 📦 Store exports in multiple locations
- 📦 Test restore procedures regularly
- 📦 Document backup procedures

## 📚 Quick Reference

### Database Management Commands
```bash
# Drop database safely (with double confirmation)
./scripts/database-migrate.sh
# Choose option 9: Drop database (with double confirmation)
# 
# The script will:
# 1. Show available databases
# 2. Ask for first confirmation (yes/no)
# 3. Ask for second confirmation (type database name)
# 4. Drop the database if both confirmations are correct

# Manage database permissions
./scripts/database-migrate.sh
# Choose option 10: Manage database permissions
# 
# The script will:
# 1. Show available databases in container
# 2. Let you select a database
# 3. Provide permission options:
#    - Check current permissions for environment user
#    - Apply permissions for environment user (MYSQL_USER/MYSQL_PASSWORD)
#    - Apply permissions for custom user
#    - Back to main menu
```

### Export Commands
```bash
# Export single database from container
./scripts/database-export.sh
# Option 3: Create migration export (single database)

# Export from source database
./scripts/database-export.sh
# Option 5: Create migration export from source

# Export all databases
./scripts/database-export.sh
# Option 4: Create migration export (all databases)
```

### Import Commands
```bash
# Import migration export
./scripts/database-migrate.sh
# Option 5: Import from migration export

# List available databases
./scripts/database-migrate.sh
# Option 6: List available databases

# List migration exports
./scripts/database-migrate.sh
# Option 7: List migration exports

# Drop database (with double confirmation)
./scripts/database-migrate.sh
# Option 9: Drop database (with double confirmation)

# Manage database permissions
./scripts/database-migrate.sh
# Option 10: Manage database permissions
```

### Source-Dependent Commands (Require Source Database)
```bash
# Migrate single database (disabled if source unavailable)
./scripts/database-migrate.sh
# Option 1: Migrate single database

# Migrate all databases (disabled if source unavailable)
./scripts/database-migrate.sh
# Option 2: Migrate all databases
```

### File Locations
- **Migration exports**: `./migrations/exports/`
- **Migration imports**: `./migrations/imports/`
- **Standard exports**: `./exports/`
- **Backups**: `./backups/`

### Environment Variables
```bash
# Required in .env file
MYSQL_ROOT_PASSWORD=your_password
SOURCE_MYSQL_USER=your_user
SOURCE_MYSQL_PASSWORD=your_password

# For automatic permission application
MYSQL_USER=your_application_user
MYSQL_PASSWORD=your_application_password
```

### Automatic Permission Application
After successful migrations (single database, SQL dump, migration export), the system automatically:
- Applies permissions for the environment user (`MYSQL_USER`)
- Creates the user if it doesn't exist
- Grants all privileges on the migrated database
- Flushes privileges to ensure immediate availability

**Note**: If `MYSQL_USER` or `MYSQL_PASSWORD` are not defined, the system will show a warning and skip permission application.

---

**Need Help?** Check the main documentation in `docs/MIGRATION_SYSTEM.md` for technical details and troubleshooting.
