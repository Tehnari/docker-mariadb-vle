# MariaDB VLE Backup System

## 📋 Table of Contents
1. [Overview](#overview)
2. [Backup Types](#backup-types)
3. [Automatic Backup System](#automatic-backup-system)
4. [Manual Backup Operations](#manual-backup-operations)
5. [Backup Management](#backup-management)
6. [Restore Procedures](#restore-procedures)
7. [Monitoring and Logs](#monitoring-and-logs)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## 🚀 Overview

The MariaDB VLE backup system provides automated daily backups using `mariadb-backup`, a native MariaDB backup tool that is faster and more reliable than traditional `mysqldump`. The system includes compression, checksum validation, and automatic cleanup.

### Key Features
- ✅ **Native MariaDB Backup**: Uses `mariadb-backup` for optimal performance
- ✅ **Automated Daily Backups**: Cron-based scheduling at 2:00 AM
- ✅ **Compression**: All backups are compressed with gzip
- ✅ **Checksum Validation**: SHA256 checksums for data integrity
- ✅ **Automatic Cleanup**: Configurable retention policy (default: 30 days)
- ✅ **Logging**: Comprehensive logging for monitoring
- ✅ **Manual Operations**: Scripts for manual backup/restore

## 📊 Backup Types

### 1. Automatic Daily Backups
- **Schedule**: Daily at 2:00 AM
- **Tool**: `mariadb-backup` (native MariaDB tool)
- **Compression**: gzip
- **Retention**: 30 days (configurable)
- **Location**: `./backups/`

### 2. Manual Backups
- **Tool**: `./scripts/backup-create.sh`
- **Compression**: gzip
- **Checksum**: SHA256 validation
- **Location**: `./backups/`

### 3. Migration Exports
- **Tool**: `./scripts/database-export.sh`
- **Purpose**: Cross-server migration
- **Metadata**: JSON metadata with database info
- **Location**: `./migrations/exports/`

## ⚙️ Automatic Backup System

### Setup
```bash
# Setup automatic daily backups
./scripts/setup-cron.sh
```

### Cron Job Details
- **Schedule**: `0 2 * * *` (Daily at 2:00 AM)
- **Script**: `./scripts/backup-daily.sh`
- **Logs**: `./logs/backup.log`
- **Working Directory**: Project root

### Configuration
The backup system uses environment variables from `.env`:
```bash
MYSQL_ROOT_PASSWORD=your_password
BACKUP_RETENTION_DAYS=30  # Optional, defaults to 30
```

### Backup Process
1. **Container Check**: Verifies MariaDB container is running
2. **Backup Creation**: Uses `mariadb-backup` with streaming
3. **Compression**: Pipes output through `gzip`
4. **Checksum**: Generates SHA256 checksum
5. **Cleanup**: Removes old backups based on retention policy
6. **Logging**: Records all operations to log file

## 🔧 Manual Backup Operations

### Create Manual Backup
```bash
# Create a manual backup
./scripts/backup-create.sh
```

**What happens:**
- Creates timestamped backup file
- Compresses with gzip
- Generates SHA256 checksum
- Shows backup size and location

### List Available Backups
```bash
# List all available backups
./scripts/backup-list.sh
```

**Output includes:**
- Backup filename and timestamp
- File size
- Checksum status
- Age of backup

### Backup Cleanup
```bash
# Manually run cleanup
./scripts/backup-cleanup.sh
```

**Features:**
- Removes backups older than retention period
- Shows cleanup statistics
- Preserves checksum files

## 📁 Backup Management

### File Structure
```
backups/
├── mariadb_backup_20241201_020000.tar.gz    # Compressed backup
├── mariadb_backup_20241201_020000.sha256    # Checksum file
├── mariadb_backup_20241202_020000.tar.gz
├── mariadb_backup_20241202_020000.sha256
└── ...
```

### Backup Naming Convention
- **Format**: `mariadb_backup_YYYYMMDD_HHMMSS.tar.gz`
- **Example**: `mariadb_backup_20241201_020000.tar.gz`
- **Checksum**: Same name with `.sha256` extension

### Retention Policy
- **Default**: 30 days
- **Configurable**: Set `BACKUP_RETENTION_DAYS` in environment
- **Automatic**: Cleanup runs after each backup
- **Manual**: Can be run independently

## 🔄 Restore Procedures

### Full Database Restore
```bash
# Restore from backup
./scripts/backup-restore.sh mariadb_backup_20241201_020000.tar.gz
```

**Process:**
1. **Validation**: Checks file existence and integrity
2. **Confirmation**: Prompts for user confirmation
3. **Stop Service**: Stops MariaDB container
4. **Clean Data**: Removes existing database files
5. **Restore**: Extracts and restores backup
6. **Start Service**: Restarts MariaDB container

### Verification
```bash
# Verify backup integrity
sha256sum -c ./backups/mariadb_backup_20241201_020000.sha256
```

### Restore Options
- **Full Restore**: Complete database replacement
- **Migration Import**: Use migration system for selective restore
- **Manual Restore**: Direct file operations

## 📊 Monitoring and Logs

### Log Files
- **Backup Logs**: `./logs/backup.log`
- **Container Logs**: `docker compose logs mariadb`
- **System Logs**: `journalctl -u docker-mariadb-vle` (if using systemd)

### Monitoring Commands
```bash
# Check backup status
ls -la ./backups/

# View recent backup logs
tail -f ./logs/backup.log

# Check cron job status
crontab -l

# Monitor container status
docker compose ps mariadb
```

### Backup Health Checks
```bash
# Verify latest backup
./scripts/backup-list.sh

# Check backup integrity
sha256sum -c ./backups/latest_backup.sha256

# Test restore (on test system)
./scripts/backup-restore.sh latest_backup.tar.gz
```

## 🛠️ Troubleshooting

### Common Issues

#### Issue 1: "Service mariadb is not running"
**Symptoms**: Backup fails with container not running error
**Solutions**:
```bash
# Start the container
docker compose up -d

# Check container status
docker compose ps mariadb

# Wait for container to be ready
docker compose exec mariadb mariadb -u root -p"password" -e "SELECT 1;"
```

#### Issue 2: "Backup failed with connection error"
**Symptoms**: mariadb-backup cannot connect to database
**Solutions**:
```bash
# Check container health
docker compose ps mariadb

# Verify database accessibility
docker compose exec mariadb mariadb -u root -p"password" -e "SHOW DATABASES;"

# Check environment variables
cat .env | grep MYSQL_ROOT_PASSWORD
```

#### Issue 3: "Cron job not running"
**Symptoms**: Automatic backups not executing
**Solutions**:
```bash
# Check cron job
crontab -l

# Reinstall cron job
./scripts/setup-cron.sh

# Check cron service
sudo systemctl status cron

# Test manual backup
./scripts/backup-daily.sh
```

#### Issue 4: "Backup file corrupted"
**Symptoms**: Checksum validation fails
**Solutions**:
```bash
# Verify checksum
sha256sum -c ./backups/backup_file.sha256

# Recreate backup
./scripts/backup-create.sh

# Check disk space
df -h ./backups/
```

#### Issue 5: "Insufficient disk space"
**Symptoms**: Backup fails due to disk space
**Solutions**:
```bash
# Check disk space
df -h

# Clean old backups
./scripts/backup-cleanup.sh

# Check backup directory size
du -sh ./backups/
```

### Debugging Commands

#### Check Backup System
```bash
# Test backup manually
./scripts/backup-daily.sh

# Check backup files
ls -la ./backups/

# Verify checksums
find ./backups/ -name "*.sha256" -exec sha256sum -c {} \;
```

#### Check Cron System
```bash
# List cron jobs
crontab -l

# Check cron logs
sudo tail -f /var/log/syslog | grep CRON

# Test cron execution
sudo run-parts /etc/cron.daily
```

#### Check Container Status
```bash
# Container status
docker compose ps

# Container logs
docker compose logs mariadb

# Database connectivity
docker compose exec mariadb mariadb -u root -p"password" -e "SELECT 1;"
```

## 📋 Best Practices

### 1. Backup Strategy
- ✅ **Daily Backups**: Automatic daily backups at 2:00 AM
- ✅ **Retention Policy**: Keep backups for 30 days
- ✅ **Offsite Storage**: Copy backups to external storage
- ✅ **Regular Testing**: Test restore procedures monthly

### 2. Monitoring
- ✅ **Log Monitoring**: Check backup logs regularly
- ✅ **Space Monitoring**: Monitor disk space usage
- ✅ **Integrity Checks**: Verify checksums periodically
- ✅ **Performance Monitoring**: Monitor backup duration

### 3. Security
- 🔒 **Access Control**: Limit access to backup directory
- 🔒 **Encryption**: Consider encrypting sensitive backups
- 🔒 **Network Security**: Secure backup transfer if offsite
- 🔒 **Password Protection**: Use strong database passwords

### 4. Performance
- ⚡ **Timing**: Schedule backups during low-traffic periods
- ⚡ **Compression**: Use gzip compression for space efficiency
- ⚡ **Cleanup**: Regular cleanup to prevent disk space issues
- ⚡ **Monitoring**: Monitor backup performance and duration

### 5. Disaster Recovery
- 📦 **Multiple Locations**: Store backups in multiple locations
- 📦 **Documentation**: Document restore procedures
- 📦 **Testing**: Regular restore testing
- 📦 **Recovery Time**: Know your recovery time objectives

## 📚 Quick Reference

### Backup Commands
```bash
# Setup automatic backups
./scripts/setup-cron.sh

# Create manual backup
./scripts/backup-create.sh

# List backups
./scripts/backup-list.sh

# Restore backup
./scripts/backup-restore.sh backup_file.tar.gz

# Cleanup old backups
./scripts/backup-cleanup.sh
```

### Monitoring Commands
```bash
# Check backup status
ls -la ./backups/

# View backup logs
tail -f ./logs/backup.log

# Check cron jobs
crontab -l

# Verify backup integrity
sha256sum -c ./backups/backup_file.sha256
```

### Configuration
```bash
# Environment variables (.env)
MYSQL_ROOT_PASSWORD=your_password
BACKUP_RETENTION_DAYS=30  # Optional

# Cron schedule
0 2 * * *  # Daily at 2:00 AM
```

### File Locations
- **Backups**: `./backups/`
- **Logs**: `./logs/backup.log`
- **Scripts**: `./scripts/backup-*.sh`
- **Configuration**: `.env`

---

**Need Help?** Check the main documentation in `README.md` for general information and `docs/MIGRATION_SYSTEM.md` for migration workflows.

