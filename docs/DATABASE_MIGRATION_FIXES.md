# Database Migration Script Fixes

## Issues Fixed

### 1. pv Command Error
**Problem**: `pv: -s: integer argument expected`
- The script was passing decimal values (e.g., "1.7M") to pv, but pv expects integer values
- Fixed by removing decimal precision from size calculation and adding size validation

### 2. mysqldump Error
**Problem**: `mysqldump: Got errno 32 on write`
- Added better error handling and connection validation
- Added `--add-drop-database` and `--create-options` flags for better compatibility

### 3. Missing Error Handling
**Problem**: Script continued even when database connection failed
- Added source database connection validation before migration
- Added proper error handling for mysqldump process
- Added environment variable validation

## Changes Made

### 1. Size Calculation Fix
```bash
# Before
source_size=$(mysql ... -e "SELECT ROUND(SUM(...) / 1024 / 1024, 1) AS 'Size (MB)' ...)

# After  
source_size=$(mysql ... -e "SELECT ROUND(SUM(...) / 1024 / 1024) AS 'Size (MB)' ...)
```

### 2. pv Command Validation
```bash
# Before
if command -v pv &> /dev/null; then

# After
if command -v pv &> /dev/null && [ "$source_size" -gt 0 ]; then
```

### 3. Added Connection Validation
```bash
# Test source database connection first
if ! mysql -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" -e "USE \`$source_db\`;" 2>/dev/null; then
    print_error "Cannot connect to source database: $source_db"
    return 1
fi
```

### 4. Enhanced mysqldump Command
```bash
mysqldump -h localhost -P 3306 -u "$SOURCE_MYSQL_USER" -p"$SOURCE_MYSQL_PASSWORD" \
  --single-transaction \
  --routines \
  --triggers \
  --add-drop-database \
  --create-options \
  "$source_db"
```

### 5. Environment Variable Validation
- Added `validate_environment()` function
- Checks for required environment variables before starting migration
- Provides clear error messages for missing variables

## Testing

To test the fixes:

1. Ensure your source database is running on localhost:3306
2. Verify your .env file has correct credentials
3. Run the migration script:
   ```bash
   ./scripts/database-migrate.sh
   ```
4. Select option 1 (Migrate single database)
5. Choose a database to migrate

## Environment Variables Required

Make sure your `.env` file contains:
```bash
MYSQL_ROOT_PASSWORD=your_container_root_password
SOURCE_MYSQL_USER=your_source_db_user
SOURCE_MYSQL_PASSWORD=your_source_db_password
```

## Troubleshooting

If you still encounter issues:

1. **Connection Error**: Check if source database is running on localhost:3306
2. **Permission Error**: Verify source database user has SELECT privileges
3. **Container Error**: Ensure MariaDB container is running (`docker compose up -d`)
4. **pv Error**: Install pv package or the script will fall back to basic progress

## Files Modified

- `scripts/database-migrate.sh` - Main migration script with all fixes applied
