# MariaDB VLE - Technical Documentation

## Architecture Overview

### Docker Compose Configuration

The project uses Docker Compose to orchestrate a MariaDB 11.2 container with the following configuration:

```yaml
services:
  mariadb:
    image: mariadb:11.2
    container_name: mariadb-vle
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MARIADB_CHARACTER_SET_SERVER: utf8mb4
      MARIADB_COLLATION_SERVER: utf8mb4_unicode_ci
      --default-character-set=utf8mb4
    volumes:
      - ./data:/var/lib/mysql
      - ./backups:/backups
      - ./init:/docker-entrypoint-initdb.d
      - ./logs:/var/log/mysql
    ports:
      - "127.0.0.1:${MYSQL_PORT}:3306"
    networks:
      - mariadb-network
    healthcheck:
      test: ["CMD", "mariadb", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}", "-e", "SELECT 1;"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

### Environment Variables

All configuration is externalized through environment variables:

```bash
# Database Configuration
MYSQL_ROOT_PASSWORD=SFad67JkU8hu
MYSQL_DATABASE=vledb
MYSQL_USER=vledb_user
MYSQL_PASSWORD=SFad15JkU8hu
MYSQL_PORT=3366

# Migration Configuration
SOURCE_MYSQL_USER=root
SOURCE_MYSQL_PASSWORD=Super_Secret_password_should_be_here

# Backup Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_TIME=02:00
```

## Character Set Configuration

The MariaDB container is configured with UTF8MB4 character set for full Unicode support:

### Environment Variables:
- `MARIADB_CHARACTER_SET_SERVER: utf8mb4` - Server character set
- `MARIADB_COLLATION_SERVER: utf8mb4_unicode_ci` - Server collation

### Command Line Options:
- `--character-set-server=utf8mb4` - Server character set
- `--collation-server=utf8mb4_unicode_ci` - Server collation

### Benefits of UTF8MB4:
- ✅ **Full Unicode Support**: Supports all Unicode characters including emojis
- ✅ **4-byte Characters**: Handles complex characters and symbols
- ✅ **Backward Compatibility**: Compatible with UTF8 data
- ✅ **Modern Standard**: Recommended for new applications

### Configuration Methods:
1. **Environment Variables** (Recommended): Set via `MARIADB_CHARACTER_SET_SERVER` and `MARIADB_COLLATION_SERVER`
2. **Command Line Parameters**: Set via `--character-set-server` and `--collation-server`
3. **Runtime Configuration**: Set via SQL commands
4. **Configuration File**: Set via `my.cnf` file

For detailed character set configuration, see **[Character Set Guide](CHARACTER_SET_GUIDE.md)**

## Script Architecture

### Script Categories

1. **Development Environment Scripts** (`dev-*.sh`)
   - Container lifecycle management
   - Status monitoring
   - Environment validation

2. **Database Management Scripts** (`database-*.sh`)
   - Migration tools
   - Export/import operations
   - Connection testing

3. **Backup Management Scripts** (`backup-*.sh`)
   - Backup creation and restoration
   - Automated backup scheduling
   - Backup maintenance

### Common Script Patterns

#### Environment Variable Loading
```bash
# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    print_error ".env file not found"
    exit 1
fi
```

#### Container Readiness Check
```bash
# Check if container is running and ready
check_container() {
    if ! docker compose ps mariadb | grep -q "Up"; then
        print_error "MariaDB container is not running!"
        exit 1
    fi
    
    # Wait for container to be ready
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" &>/dev/null; then
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    
    print_error "Container not responding"
    exit 1
}
```

#### Progress Indicators
```bash
# Progress bar function
show_progress() {
    local current="$1"
    local total="$2"
    local operation="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %3d%% %s (%d/%d)" "$percentage" "$operation" "$current" "$total"
}
```

## Database Operations

### Migration Process

1. **Source Database Connection**
   ```bash
   mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD"
   ```

2. **Target Database Connection**
   ```bash
   docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}"
   ```

3. **Data Transfer with Progress**
   ```bash
   mysqldump -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" \
     --single-transaction --routines --triggers "$source_db" | \
   pv -s "${source_size}M" | \
   docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "$target_db"
   ```

### Backup Operations

#### Full Backup
```bash
docker compose exec -T mariadb mariadb-backup \
  --backup \
  --target-dir=/tmp/backup \
  --user=root \
  --password="${MYSQL_ROOT_PASSWORD}" \
  --stream=xbstream | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"
```

#### Backup Restoration
```bash
gunzip -c "${BACKUP_DIR}/${BACKUP_FILE}" | \
docker compose exec -T mariadb mariadb-backup \
  --copy-back \
  --target-dir=/tmp/restore \
  --user=root \
  --password="${MYSQL_ROOT_PASSWORD}"
```

## Error Handling

### Common Error Patterns

1. **Connection Errors**
   ```bash
   # Check container status
   docker compose ps mariadb
   
   # Check logs
   docker compose logs mariadb --tail=20
   
   # Test connection
   docker compose exec mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;"
   ```

2. **Environment Variable Issues**
   ```bash
   # Verify environment loading
   source .env
   echo "MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}"
   ```

3. **Permission Issues**
   ```bash
   # Fix data directory permissions
   sudo chown -R 999:999 data/
   sudo chmod -R 755 data/
   ```

### Debugging Scripts

#### Enable Debug Mode
```bash
# Add to script for debugging
set -x  # Enable debug mode
set -e  # Exit on error
```

#### Verbose Output
```bash
# Enable verbose output for commands
docker compose exec -T mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" 2>&1
```

## Performance Optimization

### Environment-Based Configuration
All performance settings are now configurable via environment variables:

```bash
# Memory settings (adjust based on available RAM and database size)
MARIADB_INNODB_BUFFER_POOL_SIZE=256M
MARIADB_INNODB_LOG_FILE_SIZE=64M
MARIADB_MAX_CONNECTIONS=200
MARIADB_QUERY_CACHE_SIZE=32M
MARIADB_TMP_TABLE_SIZE=64M
MARIADB_MAX_HEAP_TABLE_SIZE=64M

# Health Check Configuration
MARIADB_HEALTH_CHECK_INTERVAL=30s
MARIADB_HEALTH_CHECK_TIMEOUT=10s
MARIADB_HEALTH_CHECK_RETRIES=3
MARIADB_HEALTH_CHECK_START_PERIOD=60s
```

### Performance Tuning Tool
Use the performance tuner to automatically optimize settings for your system:

```bash
# Analyze your system and get recommendations
./scripts/performance-tuner.sh --analyze

# Generate optimized configuration
./scripts/performance-tuner.sh --generate

# Apply optimized settings
./scripts/performance-tuner.sh --apply

# Show current configuration
./scripts/performance-tuner.sh --current
```

### Performance Optimization Guidelines

#### Small Systems (<4GB RAM)
- **InnoDB Buffer Pool**: 60% of available RAM
- **Suitable for**: Small databases (<1GB), development, testing
- **Max Connections**: CPU cores × 50

#### Medium Systems (4-8GB RAM)
- **InnoDB Buffer Pool**: 70% of available RAM
- **Suitable for**: Medium databases (1-10GB), moderate concurrent users
- **Max Connections**: CPU cores × 50

#### Large Systems (>8GB RAM)
- **InnoDB Buffer Pool**: Balanced values (16GB for very large systems with 25GB+ databases)
- **InnoDB Log File**: Balanced for large databases (2GB for 25GB+ databases)
- **Suitable for**: Large databases (10-25GB+), high concurrent users, production
- **Max Connections**: CPU cores × 40 (max 800 for large databases)
- **Startup Time**: Moderate startup time, optimized for large databases
- **Large Transactions**: Adequate log space for large database operations
- **Cache Ratio**: 50-70% of database size for optimal performance (max 1000)

### Script Performance

1. **Progress Indicators**: Use `pv` for real-time progress
2. **Parallel Operations**: Use background processes where appropriate
3. **Memory Management**: Monitor memory usage during large operations
4. **Network Optimization**: Use local connections when possible

## Security Considerations

### Network Security
- All external connections bound to localhost (127.0.0.1)
- No public port exposure
- Docker network isolation with automatic subnet assignment
- Named network (`mariadb-network`) for easy identification
- Automatic subnet assignment prevents conflicts with other Docker Compose projects

### Data Security
- Environment variables for all credentials
- No hardcoded passwords in scripts
- Checksum verification for backups
- Proper file permissions

### Access Control
- Root access limited to container operations
- User-specific database access
- Backup encryption (optional)

## Monitoring and Logging

### Container Monitoring
```bash
# Health check
docker compose ps

# Resource usage
docker stats mariadb-vle

# Log monitoring
docker compose logs mariadb --follow
```

### Database Monitoring
```bash
# Connection status
docker compose exec mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW PROCESSLIST;"

# Performance metrics
docker compose exec mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'Connections';"
```

### Script Monitoring
- Progress indicators for long operations
- Timing information for all operations
- Error logging with timestamps
- Operation status reporting

## Development Guidelines

### Script Development Standards

1. **Environment Variables**: Always use `.env` file
2. **Error Handling**: Include proper error checking
3. **Progress Indicators**: Add progress for long operations
4. **Documentation**: Include usage examples
5. **Testing**: Test with various scenarios

### Code Quality

```bash
# Script template
#!/bin/bash

# Copyright (c) 2025 - See AUTHORS file for contributors
# Licensed under MIT License

set -e

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Function definitions
# ... script logic ...

# Main execution
main "$@"
```

### Testing Procedures

1. **Unit Testing**: Test individual functions
2. **Integration Testing**: Test complete workflows
3. **Error Testing**: Test error conditions
4. **Performance Testing**: Test with large datasets

## Troubleshooting Guide

### Container Issues

#### Container Won't Start
```bash
# Check Docker Compose syntax
docker compose config

# Check resource availability
docker system df

# Check port conflicts
netstat -tulpn | grep 3366
```

#### Database Connection Issues
```bash
# Test container connectivity
docker compose exec mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;"

# Check environment variables
echo "MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}"

# Verify container logs
docker compose logs mariadb --tail=50
```

### Script Issues

#### Permission Denied
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Fix data directory permissions
sudo chown -R 999:999 data/
```

#### Environment Variable Issues
```bash
# Verify .env file exists
ls -la .env

# Test environment loading
source .env && echo "Variables loaded successfully"
```

#### Progress Indicator Issues
```bash
# The script now automatically checks for pv and provides installation guidance
# If you see a warning about pv not being installed, follow the instructions shown

# Manual check if needed:
which pv

# Install pv if missing (Ubuntu/Debian):
sudo apt-get install pv

# Other platforms:
# CentOS/RHEL: sudo yum install pv
# macOS: brew install pv
```

## Maintenance Procedures

### Regular Maintenance

1. **Backup Verification**
   ```bash
   ./scripts/backup-list.sh
   ./scripts/backup-cleanup.sh
   ```

2. **Log Rotation**
   ```bash
   # Rotate logs
   find logs/ -name "*.log" -mtime +7 -delete
   ```

3. **Database Optimization**
   ```bash
   # Optimize tables
   docker compose exec mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "OPTIMIZE TABLE table_name;"
   ```

### Update Procedures

1. **Script Updates**
   ```bash
   # Backup current scripts
   cp -r scripts/ scripts_backup_$(date +%Y%m%d)
   
   # Update scripts
   # ... update process ...
   
   # Test updated scripts
   ./scripts/dev-status.sh
   ```

2. **Container Updates**
   ```bash
   # Update container
   docker compose pull
   docker compose up -d
   ```

---

**Last Updated:** 2025-08-06 14:30:00 UTC
**Technical Version:** 1.0.0
