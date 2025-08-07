# MariaDB VLE - Setup Guide

## 🚀 Quick Setup

### Prerequisites
- Docker and Docker Compose installed
- Git (for cloning the repository)
- Basic Linux command line knowledge

### Step 1: Download and Prepare
```bash
# Clone the repository
git clone <repository-url>
cd docker-mariadb-vle

# Or download and extract the project files
# Ensure you have all the files in the docker-mariadb-vle directory
```

### Step 2: Configure Environment (CRITICAL)
**⚠️ THIS STEP IS CRITICAL - DO NOT SKIP**

Before starting the container, you must configure the database password:

```bash
# Edit the environment file
nano .env
```

**Replace the placeholder password:**
```
MYSQL_ROOT_PASSWORD=your_secure_root_password_here
```

**With a real password:**
```
MYSQL_ROOT_PASSWORD=my_secure_password_2024
```

**Why this is critical:**
- The container initializes with the password from `.env`
- Once initialized, the password cannot be changed without data loss
- Using placeholder passwords will cause authentication failures
- All scripts will fail to connect to the database

### Step 3: Start the Container
```bash
# Start the MariaDB container
docker compose up -d

# Check if it's running
docker compose ps
```

### Step 4: Verify Installation
```bash
# Test database connection
docker compose exec mariadb mariadb -u root -p"my_secure_password_2024" -e "SELECT 1;"

# Test migration script
./scripts/database-migrate.sh
```

## 🔧 Advanced Configuration

### Performance Optimization
```bash
# Analyze your system
./scripts/performance-tuner.sh --analyze

# Generate optimized settings
./scripts/performance-tuner.sh --generate

# Apply optimized settings
./scripts/performance-tuner.sh --apply
```

### Setup Daily Backups
```bash
# Install cron job for daily backups
./scripts/setup-cron.sh
```

### Install as System Service
```bash
# Install as systemd service
sudo ./install.sh

# Start the service
sudo systemctl start docker-mariadb-vle

# Enable auto-start
sudo systemctl enable docker-mariadb-vle
```

## 🚨 Troubleshooting

### Issue: "Access denied for user 'root'@'localhost'"
**Symptoms:**
- Container starts but scripts fail with authentication errors
- Migration script shows "MariaDB container is not responding"

**Solution:**
```bash
# 1. Stop the container
docker compose down

# 2. Check current password
grep MYSQL_ROOT_PASSWORD .env

# 3. If it shows placeholder, update it
nano .env
# Change to real password

# 4. Remove old data (this will delete all databases)
sudo rm -rf data/

# 5. Restart with new password
docker compose up -d
```

### Issue: Container won't start
```bash
# Check Docker Compose syntax
docker compose config

# Check logs
docker compose logs mariadb

# Check available ports
netstat -tlnp | grep 3366
```

### Issue: Permission denied
```bash
# Fix script permissions
chmod +x ./scripts/*.sh

# Fix directory permissions
chmod 755 ./migrations/
chmod 755 ./backups/
```

## 📋 Verification Checklist

After setup, verify these items:

- [ ] Container is running: `docker compose ps`
- [ ] Container is healthy: Status shows "(healthy)"
- [ ] Database connection works: `docker compose exec mariadb mariadb -u root -p"password" -e "SELECT 1;"`
- [ ] Migration script starts: `./scripts/database-migrate.sh`
- [ ] Export script starts: `./scripts/database-export.sh`
- [ ] Backup script works: `./scripts/backup-daily.sh`

## 🔒 Security Notes

### Password Security
- Use strong, unique passwords
- Never use placeholder passwords in production
- Store passwords securely
- Consider using password managers

### Network Security
- Container is bound to localhost (127.0.0.1)
- No external port exposure by default
- Use firewall rules if needed

### Data Security
- Regular backups are essential
- Monitor disk space usage
- Keep MariaDB updated
- Monitor logs for suspicious activity

## 📚 Next Steps

After successful setup:

1. **Read the Documentation:**
   - [Migration User Guide](MIGRATION_USER_GUIDE.md)
   - [Technical Documentation](TECHNICAL.md)
   - [Folder Structure Guide](FOLDER_STRUCTURE.md)

2. **Test Basic Operations:**
   - Create a test database
   - Export and import databases
   - Test backup and restore

3. **Configure for Production:**
   - Set up monitoring
   - Configure automated backups
   - Implement security best practices

## 🆘 Getting Help

If you encounter issues:

1. Check the [Troubleshooting section](MIGRATION_USER_GUIDE.md#troubleshooting)
2. Review the [Technical Documentation](TECHNICAL.md)
3. Check container logs: `docker compose logs mariadb`
4. Verify environment variables: `cat .env`

---

**Remember:** Always set a proper password in `.env` before first container startup!
