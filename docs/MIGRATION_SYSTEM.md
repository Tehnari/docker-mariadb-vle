# Database Migration System

## Overview

The enhanced migration system provides a complete solution for exporting and importing databases across different servers with metadata preservation, progress tracking, and compression support.

## Features

### 🚀 Migration Exports
- **Metadata Preservation**: Stores database information, size, table counts, and export options
- **Progress Tracking**: Real-time progress bars for export and import operations
- **Compression Support**: Optional gzip compression to reduce file sizes
- **Checksum Validation**: SHA256 checksums for data integrity verification
- **Cross-Server Compatibility**: Works across different MariaDB servers

### 📁 Folder Structure
```
migrations/
├── exports/
│   ├── 20241201_143000_gallery2/
│   │   ├── metadata.json
│   │   ├── database.sql.gz
│   │   └── checksum.sha256
│   └── 20241201_143000_idpsite/
│       ├── metadata.json
│       ├── database.sql.gz
│       └── checksum.sha256
└── imports/
    └── (temporary import files)
```

## Usage

### Creating Migration Exports

#### Using database-export.sh
```bash
./scripts/database-export.sh
```

**Options:**
1. **Export single database** - Standard export
2. **Export all databases** - Standard export for all
3. **Create migration export (single database)** - Enhanced export with metadata
4. **Create migration export (all databases)** - Enhanced export for all
5. **List available databases** - Show databases in container
6. **List migration exports** - Show available migration exports
7. **Exit**

#### Migration Export Features
- ✅ Progress bars with `pv` command
- ✅ Metadata generation (database info, size, table counts)
- ✅ Optional compression
- ✅ Checksum generation
- ✅ Timestamped directories
- ✅ Cross-server compatibility

### Importing Migration Exports

#### Using database-migrate.sh
```bash
./scripts/database-migrate.sh
```

**Options:**
1. **Migrate single database** - Direct migration from source
2. **Migrate all databases** - Direct migration for all
3. **Import SQL dump file** - Import from SQL file
4. **Import from compressed backup** - Import from backup
5. **Import from migration export** - Import from migration export
6. **List available databases** - Show databases
7. **List migration exports** - Show available exports
8. **Test database connection** - Test connections
9. **Drop database (with double confirmation)** - Safely drop databases
10. **Manage database permissions** - Check and apply user permissions
11. **Exit**

#### Migration Import Features
- ✅ Metadata validation and display
- ✅ Target database name specification
- ✅ Progress bars for import
- ✅ Checksum validation
- ✅ Existing database handling
- ✅ Compressed file support
- ✅ Automatic permission application after successful migrations
- ✅ Database permission management for environment users
- ✅ Custom user permission support

## Permission Management

### Overview
The migration system includes comprehensive permission management to ensure that application users have proper access to migrated databases.

### Features
- **Automatic Permission Application** - Permissions are automatically applied after successful migrations
- **Environment User Support** - Uses `MYSQL_USER` and `MYSQL_PASSWORD` from environment variables
- **Custom User Support** - Apply permissions for custom users with manual input
- **Permission Checking** - Verify current user permissions with detailed output
- **User Creation** - Automatically creates users if they don't exist
- **Privilege Flushing** - Ensures permissions are immediately available

### Permission Management Menu
When selecting option 10 "Manage database permissions", you can:

1. **Check current permissions** - Verify if environment user has access to selected database
2. **Apply permissions for environment user** - Grant permissions using `MYSQL_USER`/`MYSQL_PASSWORD`
3. **Apply permissions for custom user** - Grant permissions for manually specified user
4. **Back to main menu** - Return to main migration menu

### Automatic Permission Application
After successful migrations (single database, SQL dump, migration export), the system automatically:
- Applies permissions for the environment user (`MYSQL_USER`)
- Creates the user if it doesn't exist
- Grants all privileges on the migrated database
- Flushes privileges to ensure immediate availability

### Example Workflow
```bash
# 1. Migrate a database
./scripts/database-migrate.sh
# Select option 1: Migrate single database
# Choose source database and target name

# 2. Check permissions (automatic after migration)
# System automatically applies permissions for MYSQL_USER

# 3. Verify permissions manually
# Select option 10: Manage database permissions
# Choose database and option 1: Check current permissions
```

## Metadata Format

### JSON Structure
```json
{
  "export_info": {
    "timestamp": "2024-12-01T14:30:00Z",
    "source_host": "container:3366",
    "source_user": "root",
    "export_tool": "database-export.sh",
    "export_type": "migration"
  },
  "database_info": {
    "original_name": "gallery2",
    "size_mb": 1.7,
    "tables_count": 15,
    "routines_count": 2,
    "triggers_count": 1
  },
  "export_options": {
    "compressed": true,
    "include_routines": true,
    "include_triggers": true,
    "single_transaction": true
  },
  "files": {
    "database_file": "20241201_143000_gallery2/database.sql.gz",
    "metadata_file": "20241201_143000_gallery2/metadata.json",
    "checksum_file": "20241201_143000_gallery2/checksum.sha256"
  }
}
```

## Workflow Examples

### Example 1: Export Database for Migration
```bash
# 1. Start the export script
./scripts/database-export.sh

# 2. Select option 3 (Create migration export)
# 3. Choose database (e.g., gallery2)
# 4. Choose export directory (default: ./migrations/exports)
# 5. Choose compression (y/N)

# Result: ./migrations/exports/20241201_143000_gallery2/
```

### Example 2: Import Migration Export
```bash
# 1. Start the migration script
./scripts/database-migrate.sh

# 2. Select option 5 (Import from migration export)
# 3. Choose migration export from list
# 4. Review metadata information
# 5. Enter target database name (or use original)
# 6. Confirm if database exists

# Result: Database imported with progress tracking
```

### Example 3: Cross-Server Migration
```bash
# Server A: Export
./scripts/database-export.sh
# Create migration export for database

# Copy migration folder to Server B
scp -r ./migrations/exports/20241201_143000_gallery2/ user@server-b:/path/to/migrations/exports/

# Server B: Import
./scripts/database-migrate.sh
# Import from migration export
```

### Example 4: Safe Database Drop
```bash
# 1. Start the migration script
./scripts/database-migrate.sh

# 2. Select option 9 (Drop database with double confirmation)
# 3. Choose database from the list
# 4. Confirm with "yes" to first warning
# 5. Type exact database name to final confirmation

# Result: Database safely dropped with comprehensive safety checks
```

## Advanced Features

### Progress Tracking
- Uses `pv` command for real-time progress bars
- Falls back to basic progress if `pv` unavailable
- Shows file size and transfer speed

### Compression
- Optional gzip compression
- Automatic detection of compressed files
- Progress tracking for compression/decompression

### Validation
- Checksum validation for data integrity
- Metadata validation
- Database connection testing
- File existence checks

### Error Handling
- Comprehensive error messages
- Graceful fallbacks
- Connection validation
- File validation

### Database Management
- Safe database drop with double confirmation
- Database listing and selection
- Automatic database list refresh
- Clear warning messages for destructive operations

## Environment Variables

Required in `.env`:
```bash
MYSQL_ROOT_PASSWORD=your_container_root_password
SOURCE_MYSQL_USER=your_source_db_user
SOURCE_MYSQL_PASSWORD=your_source_db_password
```

## Dependencies

### Required
- `docker` and `docker compose`
- `mariadb-client` or `mysql-client`
- `gzip` for compression
- `sha256sum` for checksums

### Optional
- `pv` for progress bars (recommended)

## Troubleshooting

### Common Issues

1. **No migration exports found**
   - Create migration exports first using `database-export.sh`
   - Check `./migrations/exports/` directory

2. **Checksum validation failed**
   - File may be corrupted during transfer
   - Re-export the database

3. **Progress bar not showing**
   - The script now automatically checks for `pv` and provides installation guidance
   - Install `pv` package: `sudo apt install pv` (Ubuntu/Debian)
   - Script will work without progress bars

4. **Permission denied**
   - Check file permissions in migrations directory
   - Ensure script has execute permissions

### Debugging

Enable verbose output:
```bash
bash -x ./scripts/database-export.sh
bash -x ./scripts/database-migrate.sh
```

Check logs:
```bash
docker compose logs mariadb
```

## Best Practices

1. **Always use migration exports** for cross-server transfers
2. **Enable compression** for large databases
3. **Validate checksums** before importing
4. **Test imports** on non-production systems first
5. **Keep migration exports** organized and documented
6. **Use descriptive database names** for target databases

## File Locations

- **Migration exports**: `./migrations/exports/`
- **Migration imports**: `./migrations/imports/`
- **Standard exports**: `./exports/`
- **Backups**: `./backups/`

## Scripts Modified

- `scripts/database-export.sh` - Enhanced with migration export functionality
- `scripts/database-migrate.sh` - Enhanced with migration import functionality
- `migrations/` - New directory structure for migration files
