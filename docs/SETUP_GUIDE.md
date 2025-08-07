# MariaDB VLE Setup Guide

This guide explains how to set up MariaDB VLE using the template-based approach.

## 🚀 Quick Start

### Basic Setup (Default Configuration)
```bash
# Clone the repository
git clone <repository-url>
cd docker-mariadb-vle

# Run setup with defaults
./scripts/setup.sh
```

### Custom Instance Setup
```bash
# Set up with custom instance name and port
./scripts/setup.sh --instance-name production --port 3367

# Set up with systemd service
./scripts/setup.sh --instance-name staging --port 3368 --install-systemd

# Set up with daily backups
./scripts/setup.sh --instance-name dev --port 3369 --setup-cron

# Complete setup (everything)
./scripts/setup.sh --instance-name prod --port 3370 --install-systemd --setup-cron
```

## 📋 Setup Options

### Instance Configuration
- `--instance-name NAME` - Set instance name (default: mariadb-vle)
- `--port PORT` - Set port (default: 3366)

### Service Management
- `--install-systemd` - Install as systemd service
- `--setup-cron` - Setup daily backups

### Maintenance
- `--reset` - Reset to template level (remove all configuration)
- `--help` - Show help information

## 🔧 What the Setup Script Does

### 1. Instance Configuration
- Creates necessary directories (data, backups, logs, etc.)
- Updates `.env` file with instance name and port
- Generates `docker-compose.yml` from template
- Sets proper permissions for scripts

### 2. Template-Based Approach
- Uses `docker-compose.template.yml` as base
- Uses `docker-mariadb-vle.service.template` for systemd
- Replaces placeholders: `{{INSTANCE_NAME}}`, `{{INSTANCE_PORT}}`
- Creates unique networks and container names

### 3. Systemd Service (Optional)
- Generates service file from template
- Installs to `/etc/systemd/system/`
- Enables auto-start on boot
- Provides systemctl commands

### 4. Cron Backups (Optional)
- Sets up daily backups at 2:00 AM
- Creates backup log file
- Removes old cron entries if they exist

## 🔄 Reset Functionality

### Reset to Template Level
```bash
# Reset everything to template state
./scripts/setup.sh --reset
```

**What Reset Does:**
- Stops and removes containers
- Removes generated files (`docker-compose.yml`, service files)
- Resets `.env` to template values
- Clears all data directories
- Removes cron jobs

### Complete Reset and Setup
```bash
# Reset and set up fresh instance
./scripts/setup.sh --reset
./scripts/setup.sh --instance-name production --port 3367
```

## 📁 Multi-Instance Setup

### Method 1: Copy and Configure
```bash
# Copy the project folder
cp -r docker-mariadb-vle docker-mariadb-vle-production
cp -r docker-mariadb-vle docker-mariadb-vle-staging

# Configure each instance
cd docker-mariadb-vle-production
./scripts/setup.sh --instance-name production --port 3367

cd ../docker-mariadb-vle-staging
./scripts/setup.sh --instance-name staging --port 3368
```

### Method 2: Reset and Reconfigure
```bash
# In the same folder, reset and reconfigure
./scripts/setup.sh --reset
./scripts/setup.sh --instance-name production --port 3367

# For another instance, copy the folder first
cp -r docker-mariadb-vle docker-mariadb-vle-staging
cd docker-mariadb-vle-staging
./scripts/setup.sh --instance-name staging --port 3368
```

## 🔒 Security Considerations

### Password Configuration
**CRITICAL:** Always set proper passwords in `.env` before starting:
```bash
# Edit the .env file
nano .env

# Set these values:
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_PASSWORD=your_secure_user_password
```

### Instance Isolation
Each instance has:
- Unique container name
- Unique port assignment
- Unique network name
- Independent data directories
- Isolated configuration

## 📊 Verification

### Check Configuration
```bash
# Verify docker-compose configuration
docker compose config

# Check instance settings
grep INSTANCE .env
```

### Start and Test
```bash
# Start the instance
docker compose up -d

# Check status
docker compose ps

# Test database connection
docker compose exec mariadb mariadb -u root -p -e "SHOW DATABASES;"
```

## 🛠️ Troubleshooting

### Common Issues

**1. Port Already in Use**
```bash
# Choose a different port
./scripts/setup.sh --instance-name production --port 3368
```

**2. Instance Name Conflicts**
```bash
# Choose a different instance name
./scripts/setup.sh --instance-name prod --port 3367
```

**3. Permission Issues**
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

**4. Reset and Start Fresh**
```bash
# Complete reset
./scripts/setup.sh --reset
./scripts/setup.sh --instance-name production --port 3367
```

### Systemd Service Issues
```bash
# Check service status
sudo systemctl status docker-production

# View logs
sudo journalctl -u docker-production -f

# Restart service
sudo systemctl restart docker-production
```

## 📚 Next Steps

After successful setup:
1. **Configure passwords** in `.env`
2. **Start the instance**: `docker compose up -d`
3. **Test the database**: Use migration scripts
4. **Set up backups**: Configure retention policy
5. **Monitor logs**: Check for any issues

## 🔗 Related Documentation

- [Migration User Guide](MIGRATION_USER_GUIDE.md) - Database migration and management
- [Backup System](BACKUP_SYSTEM.md) - Backup and restore procedures
- [Technical Documentation](TECHNICAL.md) - Architecture and configuration details
- [Folder Structure](FOLDER_STRUCTURE.md) - Project organization
