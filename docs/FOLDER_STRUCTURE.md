# MariaDB VLE - Folder Structure Guide

## 📁 Project Folder Overview

The MariaDB VLE project uses a well-organized folder structure to separate different types of data, backups, migrations, and documentation. This guide explains the purpose and usage of each folder.

## ⚠️ Critical Setup Information

### Password Configuration (IMPORTANT)
**Before starting the container for the first time:**
1. Open `.env` file: `nano .env`
2. Replace the placeholder password:
   ```
   MYSQL_ROOT_PASSWORD=your_secure_root_password_here
   ```
   With a real password:
   ```
   MYSQL_ROOT_PASSWORD=my_secure_password_2024
   ```
3. Save the file and start the container

**Why this is critical:**
- The container initializes with the password from `.env`
- Once initialized, the password cannot be changed without data loss
- Using placeholder passwords will cause authentication failures
- If you accidentally use a placeholder, you must reset the container data

## 🗂️ Folder Structure

```
docker-mariadb-vle/
├── 📁 migrations/          # Database migration exports and imports
│   ├── 📁 exports/        # Internal migration exports
│   └── 📁 imports/        # External migration imports
├── 📁 backups/            # Automated and manual database backups
├── 📁 docs/              # Project documentation
├── 📁 data/              # MariaDB data files (persistent storage)
├── 📁 logs/              # MariaDB and application logs
├── 📁 init/              # Database initialization scripts
├── 📁 scripts/           # Management and utility scripts
├── 📁 exports/           # Standard database exports (legacy)
└── 📄 Configuration files
    ├── docker-compose.yml
    ├── .env
    └── README.md
```

## 📤 Migrations Folder (`./migrations/`)

### Purpose
The `migrations/` folder is designed for **cross-platform database migration** with metadata preservation, checksum validation, and progress tracking.

### Structure
```
migrations/
├── exports/              # Internal migration exports
│   ├── 20241201_143000_gallery2/
│   │   ├── metadata.json      # Export information and database details
│   │   ├── database.sql.gz    # Compressed database dump
│   │   └── checksum.sha256    # Data integrity verification
│   └── 20241201_143000_idpsite/
│       ├── metadata.json
│       ├── database.sql.gz
│       └── checksum.sha256
└── imports/              # External migration imports
    └── (external migration packages)
```

### Usage

#### Creating Migration Exports
```bash
# Export from container database
./scripts/database-export.sh
# Choose option 3: Create migration export (single database)

# Export from source database
./scripts/database-export.sh
# Choose option 5: Create migration export from source

# Export all databases
./scripts/database-export.sh
# Choose option 4: Create migration export (all databases)
```

#### Importing Migration Exports
```bash
# Import migration export
./scripts/database-migrate.sh
# Choose option 5: Import from migration export
```

#### Cross-Platform Migration
```bash
# Server A: Export
./scripts/database-export.sh
# Creates: ./migrations/exports/YYYYMMDD_HHMMSS_dbname/

# Transfer to Server B
scp -r ./migrations/exports/20241201_143000_dbname/ user@server-b:/path/to/migrations/imports/

# Server B: Import
./scripts/database-migrate.sh
# Select from imports directory
```

### Key Features
- ✅ **Metadata Preservation**: JSON files with database information
- ✅ **Compression**: All exports are compressed with gzip
- ✅ **Checksum Validation**: SHA256 for data integrity
- ✅ **Progress Tracking**: Real-time progress bars
- ✅ **Cross-Platform**: Designed for server-to-server migration
- ✅ **Target Naming**: Custom database names on import

## 📦 Backups Folder (`./backups/`)

### Purpose
The `backups/` folder stores **automated daily backups** and **manual backups** created using the native MariaDB backup tool (`mariadb-backup`).

### Structure
```
backups/
├── mariadb_backup_20241201_020000.tar.gz    # Daily automated backup
├── mariadb_backup_20241201_020000.sha256    # Checksum for verification
├── mariadb_backup_20241201_143000.tar.gz    # Manual backup
├── mariadb_backup_20241201_143000.sha256    # Checksum for verification
└── ...
```

### Usage

#### Automatic Backups
```bash
# Setup automatic daily backups (2:00 AM)
./scripts/setup-cron.sh

# Check backup status
ls -la ./backups/

# Verify backup integrity
sha256sum -c ./backups/mariadb_backup_20241201_020000.sha256
```

#### Manual Backups
```bash
# Create manual backup
./scripts/backup-create.sh

# List available backups
./scripts/backup-list.sh

# Restore from backup
./scripts/backup-restore.sh mariadb_backup_20241201_020000.tar.gz
```

#### Backup Management
```bash
# Clean old backups (retention policy)
./scripts/backup-cleanup.sh

# Check backup directory size
du -sh ./backups/
```

### Key Features
- ✅ **Native MariaDB Backup**: Uses `mariadb-backup` for optimal performance
- ✅ **Automated Scheduling**: Daily backups at 2:00 AM via cron
- ✅ **Compression**: All backups compressed with gzip
- ✅ **Checksum Validation**: SHA256 for data integrity
- ✅ **Retention Policy**: Configurable cleanup (default: 30 days)
- ✅ **Full Database Backup**: Complete database state preservation

## 📚 Documentation Folder (`./docs/`)

### Purpose
The `docs/` folder contains **comprehensive documentation** for all aspects of the MariaDB VLE system.

### Structure
```
docs/
├── README.md                    # Main documentation index
├── TECHNICAL.md                 # Technical architecture and development guide
├── CHANGELOG.md                 # Version history and changes
├── INDEX.md                     # Documentation navigation
├── TASK_TRACKER.md              # Development progress tracking
├── DATABASE_MIGRATION_FIXES.md  # Migration system fixes and improvements
├── MIGRATION_SYSTEM.md          # Migration system technical documentation
├── MIGRATION_USER_GUIDE.md      # Migration system user guide
├── BACKUP_SYSTEM.md             # Backup system documentation
├── FOLDER_STRUCTURE.md          # This folder structure guide
└── ...
```

### Usage

#### For Users
```bash
# Start with main documentation
cat docs/README.md

# Check migration user guide
cat docs/MIGRATION_USER_GUIDE.md

# Review backup system
cat docs/BACKUP_SYSTEM.md
```

#### For Developers
```bash
# Technical architecture
cat docs/TECHNICAL.md

# Migration system details
cat docs/MIGRATION_SYSTEM.md

# Development progress
cat docs/TASK_TRACKER.md
```

#### For Administrators
```bash
# System overview
cat docs/README.md

# Folder structure (this guide)
cat docs/FOLDER_STRUCTURE.md

# Troubleshooting
cat docs/TECHNICAL.md
```

### Key Features
- ✅ **Comprehensive Coverage**: All system aspects documented
- ✅ **User-Friendly**: Clear examples and workflows
- ✅ **Technical Details**: Architecture and development guides
- ✅ **Troubleshooting**: Common issues and solutions
- ✅ **Cross-References**: Links between related documents

## 💾 Data Folder (`./data/`)

### Purpose
The `data/` folder contains **persistent MariaDB data files** that survive container restarts and updates.

### Structure
```
data/
├── aria_log.00000001          # Aria storage engine log files
├── aria_log_control           # Aria log control file
├── ibdata1                    # InnoDB system tablespace
├── ib_logfile0                # InnoDB redo log files
├── ib_logfile1                # InnoDB redo log files
├── mysql/                     # MySQL system database
│   ├── user.MAI              # User privileges
│   ├── user.MAD              # User privileges data
│   ├── db.MAI                # Database privileges
│   ├── db.MAD                # Database privileges data
│   └── ...                   # Other system tables
├── performance_schema/         # Performance schema data
├── sys/                       # Sys schema data
├── idpsite/                   # Application databases
├── gallery2/                  # Application databases
└── ...
```

### Usage

#### Data Persistence
```bash
# Data survives container restarts
docker compose restart mariadb

# Data survives container updates
docker compose down
docker compose up -d

# Data survives system reboots
sudo reboot
```

#### Data Backup
```bash
# Backup data directory
tar -czf data_backup_$(date +%Y%m%d).tar.gz ./data/

# Restore data directory
tar -xzf data_backup_20241201.tar.gz
```

#### Data Management
```bash
# Check data directory size
du -sh ./data/

# List databases
docker compose exec mariadb mariadb -u root -p"password" -e "SHOW DATABASES;"

# Check data integrity
docker compose exec mariadb mariadb -u root -p"password" -e "CHECK TABLE table_name;"
```

### Key Features
- ✅ **Persistent Storage**: Data survives container lifecycle
- ✅ **Docker Volume**: Mounted as Docker volume
- ✅ **Performance Optimized**: Optimized for MariaDB performance
- ✅ **Backup Compatible**: Works with backup and migration systems
- ✅ **Multi-Database Support**: Supports multiple application databases

## 📋 Logs Folder (`./logs/`)

### Purpose
The `logs/` folder stores **MariaDB log files** and **application logs** for monitoring and troubleshooting.

### Structure
```
logs/
├── backup.log                 # Backup operation logs
├── mariadb.log               # MariaDB server logs
├── error.log                 # MariaDB error logs
├── slow_query.log            # Slow query logs (if enabled)
└── ...
```

### Usage

#### Monitoring Logs
```bash
# View backup logs
tail -f ./logs/backup.log

# View MariaDB logs
docker compose logs mariadb

# View error logs
tail -f ./logs/error.log
```

#### Log Management
```bash
# Check log file sizes
du -sh ./logs/*

# Rotate old logs
find ./logs/ -name "*.log" -mtime +7 -delete

# Archive logs
tar -czf logs_$(date +%Y%m%d).tar.gz ./logs/
```

### Key Features
- ✅ **Comprehensive Logging**: All operations logged
- ✅ **Timestamped Entries**: All log entries include timestamps
- ✅ **Error Tracking**: Detailed error information
- ✅ **Performance Monitoring**: Slow query and performance logs
- ✅ **Log Rotation**: Automatic cleanup of old logs

## 🔧 Scripts Folder (`./scripts/`)

### Purpose
The `scripts/` folder contains **all management and utility scripts** for the MariaDB VLE system.

### Structure
```
scripts/
├── dev-*.sh                  # Development environment scripts
│   ├── dev-start.sh         # Start containers
│   ├── dev-stop.sh          # Stop containers
│   ├── dev-restart.sh       # Restart containers
│   ├── dev-down.sh          # Remove containers
│   └── dev-status.sh        # Show status
├── database-*.sh             # Database management scripts
│   ├── database-migrate.sh  # Migration tool
│   └── database-export.sh   # Export tool
├── (deprecated) performance-tuner.sh
├── backup-*.sh               # Backup management scripts
│   ├── backup-create.sh     # Create manual backup
│   ├── backup-daily.sh      # Automated daily backup
│   ├── backup-restore.sh    # Restore from backup
│   ├── backup-cleanup.sh    # Clean old backups
│   └── backup-list.sh       # List backups
├── setup-*.sh                # Setup scripts
│   └── setup-cron.sh        # Setup cron jobs
└── ...
```

### Usage

#### Development Environment
```bash
# Start development environment
./scripts/dev-start.sh

# Check status
./scripts/dev-status.sh

# Stop environment
./scripts/dev-stop.sh
```

#### Database Management
```bash
# Database migration
./scripts/database-migrate.sh

# Database export
./scripts/database-export.sh
```

#### Backup Management
```bash
# Create backup
./scripts/backup-create.sh

# Setup automatic backups
./scripts/setup-cron.sh

# Restore backup
./scripts/backup-restore.sh backup_file.tar.gz
```

### Key Features
- ✅ **Comprehensive Coverage**: All system operations covered
- ✅ **Interactive Menus**: User-friendly interactive interfaces
- ✅ **Progress Tracking**: Real-time progress indicators
- ✅ **Error Handling**: Comprehensive error checking
- ✅ **Environment Variables**: All scripts use `.env` configuration

## 📁 Exports Folder (`./exports/`)

### Purpose
The `./exports/` folder is a **legacy folder** for standard database exports (without metadata). It's being replaced by the `./migrations/exports/` folder.

### Structure
```
exports/
├── database_20241201_143000.sql.gz    # Standard database export
├── all_databases_20241201_143000.sql.gz
└── ...
```

### Usage (Legacy)
```bash
# Legacy export (not recommended)
./scripts/database-export.sh
# Choose option 1 or 2 (standard export)

# Use migration exports instead
./scripts/database-export.sh
# Choose option 3, 4, or 5 (migration export)
```

### Migration to New System
- **Old**: Use `./exports/` for standard exports
- **New**: Use `./migrations/exports/` for migration exports
- **Recommendation**: Use migration exports for all new operations

## 🔄 Folder Relationships

### Data Flow
```
Source Database → migrations/exports/ → Target Server → migrations/imports/ → Target Database
     ↓
backups/ (daily backups)
     ↓
data/ (persistent storage)
```

### Backup Strategy
```
data/ → backups/ (automated daily)
  ↓
migrations/exports/ (manual migration exports)
  ↓
Cross-platform transfer
```

### Documentation Support
```
docs/ → All operations documented
  ↓
scripts/ → Implement documented features
  ↓
All folders → Covered in documentation
```

## 📋 Best Practices

### Folder Organization
- ✅ **Separate Concerns**: Each folder has a specific purpose
- ✅ **Clear Naming**: Folder names clearly indicate their purpose
- ✅ **Consistent Structure**: Similar items grouped together
- ✅ **Documentation**: All folders documented and explained

### Data Management
- ✅ **Backup Strategy**: Multiple backup types for different needs
- ✅ **Migration Strategy**: Cross-platform migration with metadata
- ✅ **Persistence**: Data survives container lifecycle
- ✅ **Monitoring**: Comprehensive logging and monitoring

### Security
- ✅ **Access Control**: Proper permissions on all folders
- ✅ **Data Integrity**: Checksum validation for all data
- ✅ **Environment Variables**: No hardcoded values
- ✅ **Network Security**: Localhost-only access

### Performance
- ✅ **Compression**: All exports and backups compressed
- ✅ **Progress Tracking**: Real-time progress indicators
- ✅ **Optimized Storage**: Efficient data storage and retrieval
- ✅ **Resource Management**: Proper cleanup and maintenance

## 🚀 Quick Reference

### Essential Commands
```bash
# Check folder structure
ls -la

# Check folder sizes
du -sh */

# Navigate to specific folders
cd migrations/exports/    # Migration exports
cd backups/              # Database backups
cd docs/                 # Documentation
cd data/                 # Database data
cd logs/                 # Log files
cd scripts/              # Management scripts
```

### Folder Purposes
- **`migrations/`**: Cross-platform database migration
- **`backups/`**: Automated and manual database backups
- **`docs/`**: Comprehensive system documentation
- **`data/`**: Persistent MariaDB data storage
- **`logs/`**: System and application logs
- **`scripts/`**: Management and utility scripts
- **`exports/`**: Legacy standard exports (deprecated)

---

**Need Help?** Check the main documentation in `docs/README.md` for general information and specific guides for each system component.

