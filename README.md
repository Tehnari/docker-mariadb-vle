# MariaDB VLE (Virtual Learning Environment) Docker Compose Service

> **Copyright (c) 2025** - See [AUTHORS](AUTHORS) for contributors  
> Licensed under MIT License - see [LICENSE](LICENSE) for details

A complete MariaDB setup with automated daily backups using `mariadb-backup`, compression, and systemd service management.
Crossplatform cases can also be used carefully (e.g. with the use of the scp command).

## Features

- **MariaDB 11.2**: Latest stable version with full Unicode support
- **⚡ Performance Tuning**: Automatic system analysis and MariaDB optimization
- **🔤 Character Set Configuration**: Environment-based UTF8MB4 character set support
- **🌐 Network Security**: Automatic subnet assignment with named networks
- **mariadb-backup**: Native MariaDB backup tool (faster and more reliable than mysqldump)
- **Compressed Backups**: All backups are compressed with gzip to save storage space
- **Checksum Verification**: SHA256 checksums for backup integrity
- **Automated Daily Backups**: Cron-based daily backups at 2:00 AM
- **Manual Backup/Restore**: Scripts for manual operations
- **Database Migration Tools**: Interactive tools for importing/exporting databases
- **Systemd Integration**: Full systemd service support
- **Health Monitoring**: Built-in health checks
- **Local Storage**: All data stored locally in subfolders

## Quick Start

### 1. Initial Setup
```bash
cd docker-mariadb-vle
./setup.sh
```

### 2. Configure Environment
Edit the `.env` file with your database credentials:
```bash
nano .env
```

### 3. Optimize Performance (Recommended)
```bash
# Analyze your system and get recommendations
./scripts/performance-tuner.sh --analyze

# Generate optimized configuration for your system
./scripts/performance-tuner.sh --generate

# Apply optimized settings
./scripts/performance-tuner.sh --apply
```

### 4. Start the Service
```bash
# Using Docker Compose directly
docker compose up -d

# Or install as systemd service
sudo ./install.sh
sudo systemctl start docker-mariadb-vle
```

### 4. Setup Daily Backups (Optional)
```bash
./scripts/setup-cron.sh
```

## Database Management

### Interactive Database Migration
```bash
./scripts/database-migrate.sh
```
**Features:**
- Import SQL dump files
- Copy database files directly from host
- Import from compressed backups
- **NEW**: Import from migration exports (cross-server)
- List available databases on host and container
- **NEW**: List migration exports
- Interactive menu-driven interface
- **Fixed Issues**: Resolved pv command errors and mysqldump connection issues
- **Enhanced Error Handling**: Better validation and error messages
- **Progress Tracking**: Improved progress bars with proper size calculation and PV installation check
- **Real-time Updates**: Database list refreshes automatically after imports
- **PV Installation Check**: Automatic detection and installation guidance for progress bars

### Enhanced Database Export
```bash
./scripts/database-export.sh
```
**Features:**
- Export single or all databases
- **NEW**: Create migration exports with metadata
- **NEW**: Progress bars for export operations
- **NEW**: Compression support with checksums
- **NEW**: Cross-server migration capability
- List available databases and migration exports

### 📚 Migration System Documentation
For comprehensive guidance on using the migration system, including cross-platform scenarios:
- **[Migration User Guide](docs/MIGRATION_USER_GUIDE.md)** - Complete user guide with scenarios and workflows
- **[Migration System Documentation](docs/MIGRATION_SYSTEM.md)** - Technical details and troubleshooting

### 🔄 Backup System Documentation
For comprehensive guidance on the automatic backup system:
- **[Backup System Documentation](docs/BACKUP_SYSTEM.md)** - Complete backup system guide with troubleshooting

### 📁 Folder Structure Guide
For understanding the project folder organization and usage:
- **[Folder Structure Guide](docs/FOLDER_STRUCTURE.md)** - Complete guide to all project folders and their purposes

### 🔤 Character Set Configuration
For comprehensive character set configuration and Unicode support:
- **[Character Set Guide](docs/CHARACTER_SET_GUIDE.md)** - Complete guide to MariaDB character set configuration

### Database Export
```bash
./scripts/database-export.sh
```
**Features:**
- Export single or all databases
- Optional compression
- Custom export directory
- Timestamped filenames

## Backup Management

### Manual Backup
```bash
./scripts/backup-create.sh
```

### List Available Backups
```bash
./scripts/backup-list.sh
```

### Restore from Backup
```bash
./scripts/backup-restore.sh mariadb_backup_20241201_143000.tar.gz
```

### Cleanup Old Backups
```bash
./scripts/backup-cleanup.sh
```

## Systemd Service Management

### Install as System Service
```bash
sudo ./install.sh
```

### Service Commands
```bash
# Start service
sudo systemctl start docker-mariadb-vle

# Stop service
sudo systemctl stop docker-mariadb-vle

# Restart service
sudo systemctl restart docker-mariadb-vle

# Check status
sudo systemctl status docker-mariadb-vle

# Enable auto-start
sudo systemctl enable docker-mariadb-vle

# Disable auto-start
sudo systemctl disable docker-mariadb-vle

# View logs
sudo journalctl -u docker-mariadb-vle -f
```

## Directory Structure

```
docker-mariadb-vle/
├── docker-compose.yml          # Main compose file
├── .env.example               # Environment template
├── .env                       # Environment variables (create from example)
├── setup.sh                   # Initial setup script
├── install.sh                 # Systemd installation script
├── docker-mariadb-vle.service # Systemd service file
├── data/                      # MariaDB data directory
├── backups/                   # Compressed backup storage
├── exports/                   # Database export directory
├── logs/                      # MariaDB and backup logs
├── init/                      # Initialization scripts
└── scripts/                   # All management scripts
    ├── backup-create.sh       # Create manual backup
    ├── backup-restore.sh      # Restore from backup
    ├── backup-list.sh         # List available backups
    ├── backup-cleanup.sh      # Cleanup old backups
    ├── backup-daily.sh        # Daily automated backup
    ├── setup-cron.sh          # Setup cron for daily backups
    ├── database-migrate.sh    # Interactive database migration
    └── database-export.sh     # Export databases from container
```

## Configuration

### Environment Variables (.env)
- `MYSQL_ROOT_PASSWORD`: Root password for MariaDB
- `MYSQL_DATABASE`: Default database name
- `MYSQL_USER`: Database user
- `MYSQL_PASSWORD`: Database user password
- `MYSQL_PORT`: Port for external access (default: 3306)
- `BACKUP_RETENTION_DAYS`: Days to keep backups (default: 30)

### Backup Configuration
- **Tool**: Uses `mariadb-backup` (native MariaDB backup tool)
- **Compression**: All backups compressed with gzip
- **Daily Backups**: Automatically created at 2:00 AM via cron
- **Retention**: Configurable via `BACKUP_RETENTION_DAYS`
- **Location**: `./backups/` directory
- **Format**: `mariadb_backup_YYYYMMDD_HHMMSS.tar.gz`
- **Integrity**: SHA256 checksums for verification

## Database Migration Features

### Import Options
1. **SQL Dump Import**: Import from .sql files
2. **Direct File Copy**: Copy database files directly from host
3. **Compressed Backup Import**: Import from compressed backups
4. **Database Listing**: View available databases on host and container
5. **Database Drop**: Safe database deletion with double confirmation

### Export Options
1. **Single Database Export**: Export specific database
2. **All Databases Export**: Export all user databases
3. **Compression Support**: Optional gzip compression
4. **Custom Directories**: Specify export location

## Why mariadb-backup?

- **Faster**: Native backup tool, much faster than mysqldump
- **More Reliable**: Handles large databases better
- **Incremental Support**: Can perform incremental backups
- **Consistent**: Provides consistent backups even during writes
- **Compression**: Built-in compression support

## Security Features

- **Network Isolation**: Containers on private Docker network
- **Local Binding**: Port bound to 127.0.0.1 only
- **Secure Passwords**: Environment-based configuration
- **Health Checks**: Automatic service monitoring
- **Checksum Verification**: Backup integrity checking

## Troubleshooting

### Check Service Status
```bash
docker compose ps
docker compose logs mariadb
```

### Check Systemd Service
```bash
sudo systemctl status docker-mariadb-vle
sudo journalctl -u docker-mariadb-vle -f
```

### Check Backup Logs
```bash
tail -f logs/backup.log
```

### Reset Database
```bash
docker compose down
sudo rm -rf data/
docker compose up -d
```

### Manual Database Access
```bash
docker compose exec mariadb mysql -u root -p
```

### Verify Backup Integrity
```bash
# Check checksum
sha256sum -c backups/mariadb_backup_YYYYMMDD_HHMMSS.sha256

# Test restore (dry run)
./scripts/backup-restore.sh mariadb_backup_YYYYMMDD_HHMMSS.tar.gz
```

## Performance Tuning

The MariaDB configuration uses environment-based settings optimized for your system:

### Automatic Optimization
```bash
# Analyze your system and get recommendations
./scripts/performance-tuner.sh --analyze

# Generate optimized configuration
./scripts/performance-tuner.sh --generate

# Apply optimized settings
./scripts/performance-tuner.sh --apply
```

### System-Specific Optimizations
- **Small Systems** (<4GB RAM): 60% buffer pool, development/testing
- **Medium Systems** (4-8GB RAM): 70% buffer pool, moderate production  
- **Large Systems** (>8GB RAM): 16GB buffer pool, high-performance production for 25GB+ databases
- **Max Connections**: CPU cores × 40 (max 800 for large databases)

### Manual Configuration
Adjust performance settings in `.env` file:
- `MARIADB_INNODB_BUFFER_POOL_SIZE`: Buffer pool size
- `MARIADB_MAX_CONNECTIONS`: Maximum concurrent connections
- `MARIADB_INNODB_LOG_FILE_SIZE`: Transaction log file size
- `MARIADB_QUERY_CACHE_SIZE`: Query cache size

## Storage Requirements

With compression enabled:
- **Typical backup size**: 50-80% smaller than uncompressed
- **Daily backup**: ~100-500MB (depending on data size)
- **Monthly storage**: ~3-15GB (30 days retention)

## Cron Job Management

### View Current Cron Jobs
```bash
crontab -l
```

### Remove Backup Cron Job
```bash
crontab -e
# Remove the line containing "backup-daily.sh"
```

### Manual Cron Job Setup
```bash
# Add to crontab manually
crontab -e

# Add this line for daily backup at 2:00 AM:
0 2 * * * cd /path/to/docker-mariadb-vle && ./scripts/backup-daily.sh >> ./logs/backup.log 2>&1
```

## Migration Examples

### Import from SQL Dump
```bash
./scripts/database-migrate.sh
# Select option 1 and provide path to .sql file
```

### Copy from Host Database
```bash
./scripts/database-migrate.sh
# Select option 2 and choose database from list
```

### Export Database
```bash
./scripts/database-export.sh
# Select database and export options
```
