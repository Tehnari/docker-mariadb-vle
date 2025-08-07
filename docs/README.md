# MariaDB VLE - Development Environment

## Overview

This project provides a complete MariaDB development environment using Docker Compose with comprehensive management scripts for database operations, backups, and migrations.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Bash shell
- `pv` (pipe viewer) for progress indicators (optional but recommended)

### Initial Setup
```bash
# Clone the repository
git clone <repository-url>
cd docker-mariadb-vle

# Start the environment
./scripts/dev-start.sh

# Check status
./scripts/dev-status.sh
```

## 📁 Project Structure

```
docker-mariadb-vle/
├── scripts/                 # Management scripts
│   ├── dev-start.sh        # Start development environment
│   ├── dev-stop.sh         # Stop containers
│   ├── dev-restart.sh      # Restart containers
│   ├── dev-down.sh         # Remove containers and networks
│   ├── dev-status.sh       # Show container status
│   ├── database-migrate.sh # Database migration tool
│   ├── database-export.sh  # Database export tool
│   ├── backup-create.sh    # Create manual backups
│   ├── backup-daily.sh     # Automated daily backups
│   ├── backup-restore.sh   # Restore from backups
│   ├── backup-cleanup.sh   # Clean old backups
│   └── backup-list.sh      # List available backups
├── data/                   # MariaDB data directory
├── logs/                   # MariaDB log files
├── backups/                # Backup storage
├── init/                   # Database initialization scripts
├── docker-compose.yml      # Docker Compose configuration
└── .env                    # Environment variables
```

## 🔧 Environment Configuration

### Environment Variables (.env)
```bash
# MariaDB Configuration
MYSQL_ROOT_PASSWORD=SFad67JkU8hu
MYSQL_DATABASE=vledb
MYSQL_USER=vledb_user
MYSQL_PASSWORD=SFad15JkU8hu
MYSQL_PORT=3366

# Source Database Configuration (for migration)
SOURCE_MYSQL_USER=root
SOURCE_MYSQL_PASSWORD=Super_Secret_password_should_be_here

# Backup Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_TIME=02:00
```

## 📋 Scripts Documentation

### Development Environment Scripts

#### `dev-start.sh`
Starts the MariaDB development environment.
```bash
./scripts/dev-start.sh
```

#### `dev-stop.sh`
Stops the MariaDB containers (keeps data).
```bash
./scripts/dev-stop.sh
```

#### `dev-restart.sh`
Restarts the MariaDB containers.
```bash
./scripts/dev-restart.sh
```

#### `dev-down.sh`
Stops and removes containers and networks.
```bash
./scripts/dev-down.sh
```

#### `dev-status.sh`
Shows container status and healthRMATION.
```bash
./scripts/dev-status.sh
```

 Pacer

### Database Management Scripts

#### `database-migrate.sh`
Interactive database migration tool with progress indicators.

**Features:**
- ✅ Real-time progress bars using `pv`
- ✅ Database size estimation
- ✅ Operation timing tracking
- ✅ Connection testing
- ✅ Multiple import options

**Usage:**
```bash
./scripts/database-migrate.sh
```

**Options:**
1. **Migrate single database** - Copy specific database with progress
2. **Migrate all databases** - Copy all databases with overall progress
3. **Import SQL dump file** - Import SQL file with progress tracking
4. **Import from compressed backup** - Restore from backup with progress
5. **List available databases** - Show databases in source and container
6. **Test database connection** - Verify connectivity
7. **Exit** - Close the tool

**Progress Indicators:**
- File sizes displayed before operations
- Real-time progress bars during transfers
- Operation duration tracking
- Database size information

#### `database-export.sh`
Export databases from the container.

**Usage:**
```bash pie
./scripts/database-export.sh
```

**Features:**
- Export single or all databases
- Compression options
- Progress tracking
- Timestamped exports

### Backup Management Scripts

####emis `backup-create.sh`
Create manual database backups.

**Usage:**
```bash
./scripts/backup-create.sh
```

**Features:**
- Full database backup with compression
- Checksum verification
- Progress tracking
- Timestamped backups

#### `backup-daily.sh`
Automated daily backup script (for cron).

**Usage:**
```bash
./scripts/backup-daily.sh
```

**Features:**
- Automated backup creation
- Old backup cleanup
- Checksum generation
- Logging with timestamps

#### `backup-restore.sh`
Restore database from backup.

**Usage:**
```bash
./scripts/backup-restore.sh <backup_file.tar.gz>
```

**Features:**
- Backup integrity verification
- Progress tracking during restore
- Safe restore process
- Automatic container management

#### `backup-cleanup.sh`
Clean old backups based on retention policy.

**Usage:**
```bash
./scripts/backup-cleanup.sh
```

#### `backup-list.sh`
List available backups.

**Usage:**
```bash
./scripts/backup-list.sh
```

## 🔍 Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check logs
docker compose logs mariadb

# Restart with fresh data
./scripts/dev-down.sh
sudo rm -rf data/* logs/*
./scripts/dev-start.sh
```

#### Connection Issues
```bash
# Test container connection
docker compose exec mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;"

# Test external connection
mysql -h localhost -P 3366 -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;"
```

#### Migration Issues
```bash
# Test migration script
./scripts/database-migrate.sh

# Check source database connection
mysql -h localhost -P 3306 -u root -p"password" -e "SHOW DATABASES;"
```

### Environment Variables
Ensure all environment variables are properly set:
```bash
# Load environment variables
source .env

# Verify variables
echo "MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}"
echo "MYSQL_PORT: ${MYSQL_PORT}"
```

## 📊 Monitoring

### Container Status
```bash
./scripts/dev-status.sh
```

### Database Health
```bash
# Check container health
docker compose ps

# Check database logs
docker compose logs mariadb --tail=50
```

### Backup Status
```bash
# List backups
./scripts/backup-list.sh

# Check backup integrity
ls -la backups/
```

## 🔒 Security

### Best Practices
- ✅ No hardcoded values in scripts
- ✅ Environment variables for all credentials
- ✅ Localhost-only port binding
- ✅ Proper file permissions
- ✅ Checksum verification for backups

### Network Security
- Containers isolated in Docker network
- External access limited to localhost (127.0.0.1)
- No public exposure of database ports

## 📈 Performance

### Optimizations
- MariaDB 11.2 with environment-based configuration
- Automatic performance tuning based on system resources
- System-specific buffer pool sizing (60% to 16GB)
- Dynamic connection limits (CPU cores × 40, max 800)
- Character set optimization (UTF8MB4)
- Proper indexing and configuration

### Performance Tuning
```bash
# Analyze system and get recommendations
./scripts/performance-tuner.sh --analyze

# Generate optimized configuration
./scripts/performance-tuner.sh --generate

# Apply optimized settings
./scripts/performance-tuner.sh --apply
```

### Monitoring
- Health checks enabled
- Progress indicators for long operations
- Timing information for all operations
- File size tracking

## 🛠️ Development

### Adding New Scripts
1. Create script in `scripts/` directory
2. Make executable: `chmod +x scripts/script-name.sh`
3. Follow naming convention: `category-action.sh`
4. Include proper error handling
5. Use environment variables (no hardcoded values)

### Script Standards
- ✅ Use environment variables from `.env`
- ✅ Include proper error handling
- ✅ Add progress indicators for long operations
- ✅ Provide clear user feedback
- ✅ Follow bash best practices

## 📝 Changelog

### Recent Updates
- ✅ Fixed all `mysql` → `mariadb` command issues
- ✅ Added comprehensive progress indicators
- ✅ Improved environment variable loading
- ✅ Enhanced error handling and user feedback
- ✅ Added timing and file size information
- ✅ Fixed healthcheck configuration
- ✅ Improved container readiness detection

### Script Improvements
- **database-migrate.sh**: Added real-time progress bars, timing, and file size tracking
- **database-export.sh**: Fixed client commands and environment loading
- **backup-*.sh**: Enhanced with proper environment variable loading
- **dev-*.sh**: Improved container management and status reporting

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review container logs: `docker compose logs mariadb`
3. Test individual components
4. Verify environment variables are loaded correctly

---

**Last Updated:** 2025-08-06 14:30:00 UTC
**Version:** 1.0.0
**Status:** ✅ Production Ready
