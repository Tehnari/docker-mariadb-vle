# MariaDB VLE (Virtual Learning Environment)

A robust, production-ready MariaDB 11.2 Docker Compose setup with comprehensive management tools, performance optimization, and multi-instance support.

## 🚀 **Quick Start**

### **Single Command Setup**
```bash
# Clone and setup
git clone <repository-url>
cd docker-mariadb-vle

# Complete setup with performance optimization
./scripts/setup.sh --instance-name production --port 3367 --install-systemd --setup-cron
./scripts/setup.sh --optimize-performance
docker compose up -d
```

### **Basic Setup**
```bash
# Basic setup with defaults
./scripts/setup.sh

# Custom instance
./scripts/setup.sh --instance-name production --port 3367

# With systemd service
./scripts/setup.sh --instance-name staging --port 3368 --install-systemd

# With daily backups
./scripts/setup.sh --instance-name dev --port 3369 --setup-cron

# Complete setup
./scripts/setup.sh --instance-name prod --port 3370 --install-systemd --setup-cron
```

## 🔧 **Setup Script Features**

### **Single Comprehensive Script**
All setup operations are now integrated into `scripts/setup.sh`:

```bash
./scripts/setup.sh --help                    # Show all options
./scripts/setup.sh --reset                   # Reset to template level
./scripts/setup.sh --instance-name prod --port 3367  # Custom setup
./scripts/setup.sh --install-systemd         # Install as systemd service
./scripts/setup.sh --setup-cron              # Setup daily backups
./scripts/setup.sh --update-passwords        # Generate new secure passwords
./scripts/setup.sh --optimize-performance    # Analyze and optimize performance
```

### **Password Security**
- **Automatic Generation**: Secure 12-character passwords (uppercase, lowercase, numbers)
- **No Special Characters**: Avoids shell/Docker conflicts
- **MariaDB Compatible**: Reliable authentication
- **Update Option**: `--update-passwords` generates new passwords

### **Performance Optimization**
- **System Analysis**: Automatic detection of RAM, CPU, disk space
- **Conservative Settings**: Balanced for large databases (25GB+)
- **Integrated Workflow**: Part of setup script
- **Automatic Application**: Updates .env directly

## 📋 **Complete Workflow Examples**

### **Production Setup**
```bash
# 1. Generate new secure passwords
./scripts/setup.sh --update-passwords

# 2. Setup instance with all features
./scripts/setup.sh --instance-name production --port 3367 --install-systemd --setup-cron

# 3. Optimize performance
./scripts/setup.sh --optimize-performance

# 4. Start container
docker compose up -d
```

### **Development Setup**
```bash
# Quick development setup
./scripts/setup.sh --instance-name dev --port 3368
./scripts/setup.sh --optimize-performance
docker compose up -d
```

### **Reset to Template**
```bash
# Reset everything to template state
./scripts/setup.sh --reset

# Then setup again
./scripts/setup.sh --instance-name fresh --port 3369
```

## 🎯 **Key Features**

### **Single Setup Script**
- **All-in-one**: Setup, passwords, performance, systemd, cron
- **Template-based**: Dynamic generation from templates
- **Multi-instance**: Support for multiple isolated instances
- **Reset functionality**: Return to template state
- **Password generation**: Secure MariaDB-compatible passwords
- **Performance optimization**: Integrated system analysis and optimization

### **Password Security**
- **12-character passwords**: Secure but simple format
- **No special characters**: Avoids shell/Docker conflicts
- **MariaDB compatible**: Reliable authentication
- **Automatic generation**: Integrated into setup workflow

### **Performance Optimization**
- **System analysis**: Automatic resource detection
- **Conservative settings**: Balanced for large databases
- **Integrated workflow**: Part of setup script
- **Automatic application**: Updates .env directly

### **Multi-Instance Support**
- **Unique names**: Each instance has unique container name
- **Unique ports**: Configurable ports for each instance
- **Unique networks**: Isolated networks per instance
- **Template-based**: Dynamic generation from templates

### **Database Management**
- **Migration tools**: Comprehensive import/export
- **Permission management**: Automatic permission handling
- **Backup system**: Automated daily backups
- **Health monitoring**: Container health checks

## 🔧 **Configuration**

### **Environment Variables**
Key configuration variables in `.env`:

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
```

### **Performance Settings**
Automatically calculated based on system resources:
- **Buffer Pool**: Up to 16GB for large systems
- **Log File Size**: Up to 2GB for large databases
- **Max Connections**: CPU cores × 40 (max 800)
- **Conservative Values**: Safe for production use

## 📁 **Project Structure**

```
docker-mariadb-vle/
├── scripts/
│   ├── setup.sh                    # Single comprehensive setup script
│   ├── database-migrate.sh         # Migration tools
│   ├── database-export.sh          # Export tools
│   ├── backup-*.sh                # Backup scripts
│   └── performance-tuner.sh        # Performance optimization
├── docker-compose.template.yml     # Template for docker-compose
├── docker-mariadb-vle.service.template  # Template for systemd
├── .env.example                   # Environment template
└── docs/                          # Comprehensive documentation
```

## 🛠 **Management Commands**

### **Container Management**
```bash
# Start/Stop/Status
docker compose up -d
docker compose down
docker compose ps

# Development scripts
./scripts/dev-start.sh
./scripts/dev-stop.sh
./scripts/dev-status.sh
```

### **Database Management**
```bash
# Migration tools
./scripts/database-migrate.sh
./scripts/database-export.sh

# Backup management
./scripts/backup-create.sh
./scripts/backup-restore.sh
./scripts/backup-list.sh
```

### **Performance Management**
```bash
# Performance optimization
./scripts/setup.sh --optimize-performance

# Monitor performance
docker stats ${INSTANCE_NAME:-mariadb-vle}
```

## 📚 **Documentation**

- **[Setup Guide](docs/SETUP_GUIDE.md)**: Detailed setup instructions
- **[Migration Guide](docs/MIGRATION_USER_GUIDE.md)**: Database migration workflows
- **[Character Set Guide](docs/CHARACTER_SET_GUIDE.md)**: UTF8MB4 configuration
- **[Task Tracker](docs/TASK_TRACKER.md)**: Complete feature tracking

## ⚠️ **Important Notes**

### **Password Security**
- **Change Default Passwords**: Always update passwords in production
- **Secure Storage**: Store passwords securely, not in version control
- **Regular Updates**: Use `--update-passwords` to generate new passwords

### **Performance Considerations**
- **Large Databases**: Performance settings optimized for 25GB+ databases
- **System Resources**: Conservative settings for stable operation
- **Monitoring**: Use `docker stats` to monitor resource usage

### **Multi-Instance Usage**
- **Unique Names**: Each instance needs unique name and port
- **Resource Isolation**: Each instance has separate data and network
- **Template Reset**: Use `--reset` to return to template state

## 🚀 **Production Deployment**

### **Recommended Workflow**
1. **Generate Passwords**: `./scripts/setup.sh --update-passwords`
2. **Setup Instance**: `./scripts/setup.sh --instance-name prod --port 3367 --install-systemd --setup-cron`
3. **Optimize Performance**: `./scripts/setup.sh --optimize-performance`
4. **Start Container**: `docker compose up -d`
5. **Verify Setup**: Test connections and performance

### **Security Checklist**
- [ ] Change default passwords
- [ ] Configure firewall rules
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Test disaster recovery

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 **Contributing**

Contributions are welcome! Please read our contributing guidelines and submit pull requests.

---

**Status**: ✅ **PRODUCTION READY** - All features implemented and tested
