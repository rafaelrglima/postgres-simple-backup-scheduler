#!/bin/bash

# PostgreSQL Database Backup Script
# This script creates PostgreSQL database backups for all databases (except system databases)
# and manages old backup files based on retention policy
#
# Installation:
#   1. Copy env.sample to .env and configure your database credentials
#   2. chmod 700 backup.sh
#
# Usage: ./backup.sh <backup_type> <retention_days>
#   Example: ./backup.sh hourly 7
#   Example: ./backup.sh monthly 365

# Get script directory (works even if script is symlinked)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from .env file
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "ERROR: .env file not found at $ENV_FILE"
    echo "Please copy env.sample to .env and configure it."
    exit 1
fi

# Validate required environment variables
if [ -z "$DB_USER" ] || [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_PASSWORD" ]; then
    echo "ERROR: Missing required database configuration in .env file"
    exit 1
fi

# Get parameters
BACKUP_TYPE="${1:-manual}"
RETENTION_DAYS="${2:-7}"

# Set backup directory relative to script location
BACKUP_DIR="$SCRIPT_DIR/${BACKUP_TYPE}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# Generate timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Log file for this backup session
LOG_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting database backup process - Type: $BACKUP_TYPE, Retention: $RETENTION_DAYS days"

# Set PGPASSWORD for passwordless authentication
export PGPASSWORD="$DB_PASSWORD"

# Get list of all databases
DATABASES=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" 2>>"$LOG_FILE")

if [ -z "$DATABASES" ]; then
    log "ERROR: Could not retrieve database list. Check PostgreSQL connection."
    exit 1
fi

# Counter for successful backups
SUCCESS_COUNT=0
FAIL_COUNT=0

# Loop through each database (using process substitution to avoid subshell)
while read -r DB_NAME; do
    # Trim whitespace
    DB_NAME=$(echo "$DB_NAME" | xargs)
    
    # Skip if empty or in exclude list
    if [ -z "$DB_NAME" ]; then
        continue
    fi
    
    # Check if database should be excluded
    SKIP=false
    for EXCLUDE_DB in $EXCLUDE_DBS; do
        if [ "$DB_NAME" = "$EXCLUDE_DB" ]; then
            SKIP=true
            log "Skipping excluded database: $DB_NAME"
            break
        fi
    done
    
    if [ "$SKIP" = true ]; then
        continue
    fi
    
    log "Backing up database: $DB_NAME"
    
    BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}_${DB_NAME}.sql"
    
    # Create database backup
    if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE" 2>>"$LOG_FILE"; then
        # Compress the backup file
        gzip "$BACKUP_FILE"
        BACKUP_FILE="${BACKUP_FILE}.gz"
        
        # Get file size for logging
        FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        log "✓ Backup completed successfully: $BACKUP_FILE (Size: $FILE_SIZE)"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        log "✗ ERROR: Backup failed for database: $DB_NAME"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done < <(echo "$DATABASES")

# Clean up old backup files
log "Cleaning up old backup files (older than $RETENTION_DAYS days)..."
OLD_BACKUP_FILES=$(find "$BACKUP_DIR" -name "backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS)

if [ -n "$OLD_BACKUP_FILES" ]; then
    echo "$OLD_BACKUP_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            log "Removing old backup: $file"
            rm -f "$file"
        fi
    done
    log "Old backup files cleanup completed"
else
    log "No old backup files found to remove"
fi

# Clean up old log files
log "Cleaning up old log files (older than $RETENTION_DAYS days)..."
OLD_LOG_FILES=$(find "$BACKUP_DIR" -name "backup_*.log" -type f -mtime +$RETENTION_DAYS)

if [ -n "$OLD_LOG_FILES" ]; then
    echo "$OLD_LOG_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            log "Removing old log: $file"
            rm -f "$file"
        fi
    done
    log "Old log files cleanup completed"
else
    log "No old log files found to remove"
fi

log "Backup process completed - Success: $SUCCESS_COUNT, Failed: $FAIL_COUNT"

# Unset password for security
unset PGPASSWORD

# Exit with error if any backups failed
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi

