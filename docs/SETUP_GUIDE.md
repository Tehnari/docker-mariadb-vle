# MariaDB VLE Setup Guide

Complete setup instructions for the MariaDB VLE (Virtual Learning Environment) with integrated password generation and performance optimization.

## 🚀 **Quick Setup**

### **Single Command Production Setup**
```bash
# Clone repository
git clone <repository-url>
cd docker-mariadb-vle

# Complete setup with all features
./scripts/setup.sh --update-passwords
./scripts/setup.sh --instance-name production --port 3367 --install-systemd --setup-cron
./scripts/setup.sh --optimize-performance
docker compose up -d
```

### **Basic Development Setup**
```bash
# Quick development setup
./scripts/setup.sh --instance-name dev --port 3368
./scripts/setup.sh --optimize-performance
docker compose up -d
```

## 🔧 **Setup Script Options**

### **Available Commands**
```bash
./scripts/setup.sh --help                    # Show all options
./scripts/setup.sh --reset                   # Reset to template level
./scripts/setup.sh --instance-name prod --port 3367  # Custom setup
./scripts/setup.sh --install-systemd         # Install as systemd service
./scripts/setup.sh --setup-cron              # Setup daily backups
./scripts/setup.sh --update-passwords        # Generate new secure passwords
./scripts/setup.sh --optimize-performance    # Analyze and optimize performance
```

### **Password Generation**
```bash
# Generate new secure passwords
./scripts/setup.sh --update-passwords

# This will:
# - Generate 12-character passwords (uppercase, lowercase, numbers)
# - Update .env.example with new passwords
# - Create backup of old passwords
# - No special characters to avoid conflicts
```

### **Performance Optimization**
```bash
# Analyze system and apply performance settings
./scripts/setup.sh --optimize-performance

# This will:
# - Analyze system resources (RAM, CPU, disk)
# - Calculate conservative performance settings
# - Apply settings to .env file
# - Create backup of current settings
```

## 📋 **Step-by-Step Setup**

### **Step 1: Initial Setup**
```bash
# Basic setup with defaults
./scripts/setup.sh

# Or customize the instance
./scripts/setup.sh --instance-name production --port 3367
```

### **Step 2: Generate Secure Passwords**
```bash
# Generate new passwords
./scripts/setup.sh --update-passwords

# Verify passwords were generated
grep "MYSQL_ROOT_PASSWORD\|MYSQL_PASSWORD" .env.example
```

### **Step 3: Optimize Performance**
```bash
# Analyze and optimize performance
./scripts/setup.sh --optimize-performance

# Verify performance settings
grep "MARIADB_INNODB_BUFFER_POOL_SIZE\|MARIADB_MAX_CONNECTIONS" .env
```

### **Step 4: Start Container**
```bash
# Start the container
docker compose up -d

# Check status
docker compose ps

# Test connection
source .env && docker compose exec mariadb mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;"
```

## 🔄 **Reset and Reconfigure**

### **Reset to Template State**
```bash
# Reset everything to template level
./scripts/setup.sh --reset

# This will:
# - Stop and remove containers
# - Remove generated files (docker-compose.yml, service files)
# - Remove .env file (return to template state)
# - Clear all data directories
# - Remove backup and temporary files
# - Remove cron jobs
```

### **Fresh Setup After Reset**
```bash
# Setup new instance
./scripts/setup.sh --instance-name fresh --port 3369
./scripts/setup.sh --optimize-performance
docker compose up -d
```

## 🏭 **Production Setup**

### **Complete Production Workflow**
```bash
# 1. Generate secure passwords
./scripts/setup.sh --update-passwords

# 2. Setup instance with all features
./scripts/setup.sh --instance-name production --port 3367 --install-systemd --setup-cron

# 3. Optimize performance
./scripts/setup.sh --optimize-performance

# 4. Start container
docker compose up -d

# 5. Verify setup
source .env && docker compose exec mariadb mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;"
```

### **Systemd Service Management**
```bash
# Service commands (after --install-systemd)
sudo systemctl start docker-production
sudo systemctl stop docker-production
sudo systemctl restart docker-production
sudo systemctl status docker-production
sudo systemctl enable docker-production
```

### **Cron Job Management**
```bash
# View cron jobs
crontab -l

# Remove cron jobs manually
crontab -r

# Check backup logs
tail -f logs/backup.log
```

## 🔧 **Configuration Details**

### **Environment Variables**
Key variables in `.env`:

```bash
# Instance Configuration
INSTANCE_NAME=mariadb-vle
INSTANCE_PORT=3366

# MariaDB Configuration
MYSQL_ROOT_PASSWORD=SmBnpe7YU4tt
MYSQL_DATABASE=vledb
MYSQL_USER=vledb_user
MYSQL_PASSWORD=My4LC791txci

# Character Set Configuration
MARIADB_CHARACTER_SET_SERVER=utf8mb4
MARIADB_COLLATION_SERVER=utf8mb4_unicode_ci

# Performance Configuration
MARIADB_INNODB_BUFFER_POOL_SIZE=16384M
MARIADB_INNODB_LOG_FILE_SIZE=2048M
MARIADB_MAX_CONNECTIONS=480
MARIADB_QUERY_CACHE_SIZE=128M
MARIADB_TMP_TABLE_SIZE=512M
MARIADB_MAX_HEAP_TABLE_SIZE=512M
```

### **Performance Settings**
Automatically calculated based on system resources:

- **Buffer Pool**: Up to 16GB for large systems (>16GB RAM)
- **Log File Size**: Up to 2GB for large databases
- **Max Connections**: CPU cores × 40 (max 800)
- **Conservative Values**: Safe for production use

### **Password Security**
- **12-character passwords**: Mix of uppercase, lowercase, numbers
- **No special characters**: Avoids shell/Docker conflicts
- **MariaDB compatible**: Reliable authentication
- **Automatic generation**: Integrated into setup workflow

## 🛠 **Troubleshooting**

### **Common Issues**

#### **1. Authentication Errors**
```bash
# Check if container is running
docker compose ps

# Check password in .env
grep "MYSQL_ROOT_PASSWORD" .env

# Test connection
source .env && docker compose exec mariadb mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;"

# If still failing, reset and reconfigure
./scripts/setup.sh --reset
./scripts/setup.sh --instance-name fresh --port 3369
```

#### **2. Port Conflicts**
```bash
# Check if port is in use
netstat -tlnp | grep 3366

# Use different port
./scripts/setup.sh --instance-name production --port 3368
```

#### **3. Performance Issues**
```bash
# Check system resources
free -h
nproc
df -h

# Re-optimize performance
./scripts/setup.sh --optimize-performance
docker compose down && docker compose up -d
```

#### **4. Reset Issues**
```bash
# Manual reset if script fails
docker compose down
sudo rm -rf data/* data/.*
rm -f docker-compose.yml
rm -f docker-*.service
rm -f .env
rm -f .env.backup.*
rm -f .env.example.backup.*
rm -f .env.optimized
crontab -r
```

### **Verification Commands**
```bash
# Check container status
docker compose ps

# Check logs
docker compose logs mariadb

# Test database connection
source .env && docker compose exec mariadb mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"

# Check performance settings
source .env && docker compose exec mariadb mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# Check character set
source .env && docker compose exec mariadb mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW VARIABLES LIKE 'character_set%';"
```

## 📚 **Next Steps**

After successful setup:

1. **Test Database Operations**: Use migration tools to import/export data
2. **Configure Backups**: Verify daily backup cron job is working
3. **Monitor Performance**: Use `docker stats` to monitor resource usage
4. **Security Hardening**: Change default passwords, configure firewall
5. **Documentation**: Review all documentation in `docs/` folder

## ⚠️ **Important Notes**

### **Security Considerations**
- **Change Default Passwords**: Always update passwords in production
- **Secure Storage**: Store passwords securely, not in version control
- **Regular Updates**: Use `--update-passwords` to generate new passwords
- **Firewall Configuration**: Configure firewall rules as needed

### **Performance Considerations**
- **Large Databases**: Performance settings optimized for 25GB+ databases
- **System Resources**: Conservative settings for stable operation
- **Monitoring**: Use `docker stats` to monitor resource usage
- **Backup Storage**: Ensure sufficient disk space for backups

### **Multi-Instance Usage**
- **Unique Names**: Each instance needs unique name and port
- **Resource Isolation**: Each instance has separate data and network
- **Template Reset**: Use `--reset` to return to template state
- **Resource Planning**: Consider system resources for multiple instances

---

**Status**: ✅ **PRODUCTION READY** - All features implemented and tested
