# MariaDB VLE (Virtual Learning Environment)

A comprehensive MariaDB Docker Compose environment with advanced database management, backup, and migration capabilities.

## ✨ Features

- **MariaDB 11.2**: Latest stable version with full Unicode support
- **⚡ Performance Tuning**: Automatic system analysis and MariaDB optimization
- **🔤 Character Set Configuration**: Environment-based UTF8MB4 character set support
- **🌐 Network Security**: Automatic subnet assignment with named networks
- **🔄 Template-Based Setup**: Clean, maintainable configuration using templates
- **🔄 Multi-Instance Support**: Run multiple instances with unique names and ports
- **mariadb-backup**: Native MariaDB backup tool (faster and more reliable than mysqldump)
- **Compressed Backups**: All backups are compressed with gzip to save storage space
- **Checksum Verification**: SHA256 checksums for backup integrity
- **Automated Daily Backups**: Cron-based daily backups at 2:00 AM
- **Manual Backup/Restore**: Scripts for manual operations
- **Database Migration Tools**: Interactive tools for importing/exporting databases
- **Systemd Integration**: Full systemd service support
- **Health Monitoring**: Built-in health checks
- **Local Storage**: All data stored locally in subfolders

## 🚀 Quick Start

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd docker-mariadb-vle

# Basic setup with defaults
./scripts/setup.sh

# Or customize the instance
./scripts/setup.sh --instance-name production --port 3367
```

### 2. Configure Passwords (CRITICAL)
```bash
# Edit the .env file
nano .env

# Set proper passwords:
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_PASSWORD=your_secure_user_password
```

### 3. Start the Instance
```bash
# Start the container
docker compose up -d

# Check status
docker compose ps
```

### 4. Test the Setup
```bash
# Test database connection
docker compose exec mariadb mariadb -u root -p -e "SHOW DATABASES;"

# Test migration tools
./scripts/database-migrate.sh
```

## 📋 Setup Options

### Basic Setup
```bash
# Default configuration
./scripts/setup.sh

# Custom instance
./scripts/setup.sh --instance-name production --port 3367
```

### Advanced Setup
```bash
# With systemd service
./scripts/setup.sh --instance-name staging --port 3368 --install-systemd

# With daily backups
./scripts/setup.sh --instance-name dev --port 3369 --setup-cron

# Complete setup
./scripts/setup.sh --instance-name prod --port 3370 --install-systemd --setup-cron
```

### Reset and Reconfigure
```bash
# Reset to template level
./scripts/setup.sh --reset

# Set up fresh instance
./scripts/setup.sh --instance-name production --port 3367
```

## 📁 Multi-Instance Setup

### Method 1: Copy and Configure
```bash
# Copy project folders
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
# In the same folder
./scripts/setup.sh --reset
./scripts/setup.sh --instance-name production --port 3367

# For another instance, copy first
cp -r docker-mariadb-vle docker-mariadb-vle-staging
cd docker-mariadb-vle-staging
./scripts/setup.sh --instance-name staging --port 3368
```

## 🗄️ Database Management

### Interactive Database Migration
```bash
./scripts/database-migrate.sh
```
**Features:**
- Import SQL dump files
- Copy database files directly from host
- Import from compressed backups
- Import from migration exports (cross-server)
- List available databases on host and container
- List migration exports
- Interactive menu-driven interface
- Database permission management
- Source database availability check

### Enhanced Database Export
```bash
./scripts/database-export.sh
```
**Features:**
- Export single or all databases
- Create migration exports with metadata
- Progress bars for export operations
- Compression support with checksums
- Cross-server migration capability

## 💾 Backup System

### Automated Backups
```bash
# Setup daily backups
./scripts/setup.sh --setup-cron

# Manual backup
./scripts/backup-create.sh

# List backups
./scripts/backup-list.sh

# Restore from backup
./scripts/backup-restore.sh
```

### Backup Features
- **Native mariadb-backup**: Faster and more reliable than mysqldump
- **Compression**: All backups compressed with gzip
- **Checksums**: SHA256 verification for integrity
- **Retention**: Configurable retention policy
- **Automation**: Daily backups at 2:00 AM

## ⚡ Performance Optimization

### Automatic Tuning
```bash
# Analyze system and optimize
./scripts/performance-tuner.sh --analyze
./scripts/performance-tuner.sh --apply
```

### Performance Features
- **System Analysis**: Automatic RAM and CPU detection
- **Conservative Values**: Safe defaults for production use
- **Environment-Based**: All settings via environment variables
- **Real-time Monitoring**: Built-in health checks

## 🔧 Systemd Service

### Install as Service
```bash
# Install as systemd service
./scripts/setup.sh --install-systemd

# Service management
sudo systemctl start docker-production
sudo systemctl stop docker-production
sudo systemctl restart docker-production
sudo systemctl status docker-production
```

## 📚 Documentation

- **[Setup Guide](docs/SETUP_GUIDE.md)** - Complete setup instructions
- **[Migration User Guide](docs/MIGRATION_USER_GUIDE.md)** - Database migration workflows
- **[Backup System](docs/BACKUP_SYSTEM.md)** - Backup and restore procedures
- **[Technical Documentation](docs/TECHNICAL.md)** - Architecture and configuration
- **[Folder Structure](docs/FOLDER_STRUCTURE.md)** - Project organization
- **[Character Set Guide](docs/CHARACTER_SET_GUIDE.md)** - Unicode configuration

## 🛠️ Troubleshooting

### Common Issues

**1. Authentication Errors**
```bash
# Check password configuration
grep MYSQL_ROOT_PASSWORD .env

# Reset and reconfigure
./scripts/setup.sh --reset
./scripts/setup.sh --instance-name production --port 3367
```

**2. Port Conflicts**
```bash
# Choose different port
./scripts/setup.sh --instance-name production --port 3368
```

**3. Permission Issues**
```bash
# Fix script permissions
chmod +x scripts/*.sh
```

### Verification
```bash
# Check configuration
docker compose config

# Check status
docker compose ps

# Test connection
docker compose exec mariadb mariadb -u root -p -e "SHOW DATABASES;"
```

## 🔒 Security

### Critical Setup Steps
1. **Set proper passwords** in `.env` before first startup
2. **Use unique instance names** for multi-instance setups
3. **Configure firewall rules** if needed
4. **Monitor logs** for suspicious activity

### Instance Isolation
- Each instance has unique container name and network
- Independent data directories
- Separate port assignments
- Isolated configurations

## 📊 Project Structure

```
docker-mariadb-vle/
├── docker-compose.template.yml     # Template for docker-compose
├── docker-mariadb-vle.service.template  # Template for systemd service
├── .env.example                   # Environment template
├── .env                           # Environment variables (generated)
├── scripts/                       # All management scripts
│   ├── setup.sh                   # Main setup script
│   ├── database-migrate.sh        # Database migration tool
│   ├── database-export.sh         # Database export tool
│   ├── backup-*.sh               # Backup management scripts
│   └── performance-tuner.sh       # Performance optimization
├── data/                          # MariaDB data directory
├── backups/                       # Compressed backup storage
├── migrations/                    # Database migration files
├── logs/                          # MariaDB and backup logs
└── docs/                          # Documentation
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Important Notes

- **Always set proper passwords** in `.env` before first startup
- **Test in development** before deploying to production
- **Regular backups** are essential for data safety
- **Monitor disk space** usage for large databases
- **Keep MariaDB updated** for security patches

---

**MariaDB VLE** - A comprehensive, production-ready MariaDB environment with advanced management capabilities.
