# Character Set Configuration Guide

## Overview

This guide explains how to specify character sets in MariaDB 11.2 using different methods.

## 🎯 **Method 1: Environment Variables (Recommended)**

### Configuration in `docker-compose.yml`
```yaml
environment:
  MARIADB_CHARACTER_SET_SERVER: utf8mb4
  MARIADB_COLLATION_SERVER: utf8mb4_unicode_ci
```

### Configuration in `.env` file
```bash
# MariaDB Character Set Configuration
MARIADB_CHARACTER_SET_SERVER=utf8mb4
MARIADB_COLLATION_SERVER=utf8mb4_unicode_ci
```

### Available Character Sets
- `utf8mb4` - Full Unicode support (recommended)
- `utf8` - UTF-8 encoding
- `latin1` - Western European
- `ascii` - ASCII encoding

### Available Collations
- `utf8mb4_unicode_ci` - Unicode case-insensitive (recommended)
- `utf8mb4_general_ci` - General case-insensitive
- `utf8mb4_bin` - Binary collation

## 🎯 **Method 2: Command Line Parameters**

### Configuration in `docker-compose.yml`
```yaml
command: >
  --default-authentication-plugin=mysql_native_password
  --character-set-server=utf8mb4
  --collation-server=utf8mb4_unicode_ci
  --innodb-buffer-pool-size=${MARIADB_INNODB_BUFFER_POOL_SIZE}
  # ... other parameters
```

## 🎯 **Method 3: Runtime Configuration**

### Connect to MariaDB and set character set
```sql
-- Set server character set
SET GLOBAL character_set_server = 'utf8mb4';
SET GLOBAL collation_server = 'utf8mb4_unicode_ci';

-- Set connection character set
SET NAMES utf8mb4;
```

### Create database with specific character set
```sql
CREATE DATABASE mydb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Create table with specific character set
```sql
CREATE TABLE mytable (
    id INT PRIMARY KEY,
    name VARCHAR(255)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 🎯 **Method 4: Configuration File**

### Create `my.cnf` file
```ini
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4

[client]
default-character-set = utf8mb4
```

### Mount configuration file in `docker-compose.yml`
```yaml
volumes:
  - ./config/my.cnf:/etc/mysql/conf.d/my.cnf:ro
```

## 🔍 **Verification Commands**

### Check current character set settings
```bash
# Connect to MariaDB
docker compose exec mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}"

# Check server character set
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';

# Check all character set variables
SHOW VARIABLES LIKE 'character_set%';
SHOW VARIABLES LIKE 'collation%';

# Check available character sets
SHOW CHARACTER SET;

# Check available collations
SHOW COLLATION WHERE Charset = 'utf8mb4';
```

### Check database character set
```sql
-- Check database character set
SELECT 
    SCHEMA_NAME,
    DEFAULT_CHARACTER_SET_NAME,
    DEFAULT_COLLATION_NAME
FROM INFORMATION_SCHEMA.SCHEMATA;
```

### Check table character set
```sql
-- Check table character set
SELECT 
    TABLE_NAME,
    TABLE_COLLATION
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'your_database_name';
```

## 📊 **Character Set Comparison**

| Character Set | Description | Storage | Unicode Support |
|---------------|-------------|---------|-----------------|
| `utf8mb4` | Full Unicode | 1-4 bytes | ✅ Complete |
| `utf8` | UTF-8 (deprecated) | 1-3 bytes | ⚠️ Limited |
| `latin1` | Western European | 1 byte | ❌ None |
| `ascii` | ASCII | 1 byte | ❌ None |

## 🎯 **Recommended Configuration**

### For Modern Applications
```bash
# Environment variables
MARIADB_CHARACTER_SET_SERVER=utf8mb4
MARIADB_COLLATION_SERVER=utf8mb4_unicode_ci
```

### Benefits of UTF8MB4
- ✅ **Full Unicode Support**: Emojis, special characters, international text
- ✅ **4-byte Characters**: Handles complex Unicode characters
- ✅ **Future-Proof**: Supports all current and future Unicode characters
- ✅ **Compatibility**: Works with modern applications and APIs

## 🔧 **Troubleshooting**

### Common Issues

#### 1. Character Set Not Applied
```bash
# Check if environment variables are loaded
docker compose exec mariadb env | grep MARIADB_CHARACTER
```

#### 2. Connection Character Set Issues
```sql
-- Set connection character set
SET NAMES utf8mb4;
```

#### 3. Database Migration Issues
```bash
# Export with specific character set
mysqldump --default-character-set=utf8mb4 database_name

# Import with specific character set
mysql --default-character-set=utf8mb4 database_name
```

## 📚 **Best Practices**

1. **Use Environment Variables**: Most flexible and Docker-friendly
2. **UTF8MB4 for New Projects**: Full Unicode support
3. **Consistent Configuration**: Use same character set across all components
4. **Test with Special Characters**: Verify emoji and international text support
5. **Document Your Choice**: Include character set in project documentation

## 🚀 **Quick Setup**

### 1. Add to `.env` file
```bash
MARIADB_CHARACTER_SET_SERVER=utf8mb4
MARIADB_COLLATION_SERVER=utf8mb4_unicode_ci
```

### 2. Restart container
```bash
docker compose down
docker compose up -d
```

### 3. Verify configuration
```bash
docker compose exec mariadb mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW VARIABLES LIKE 'character_set_server';"
```

## 📖 **References**

- [MariaDB Character Sets Documentation](https://mariadb.com/kb/en/character-sets/)
- [UTF8MB4 Guide](https://mariadb.com/kb/en/utf8mb4/)
- [Docker MariaDB Image](https://hub.docker.com/_/mariadb/)
