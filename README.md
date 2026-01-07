# PostgreSQL Simple Backup Scheduler

A lightweight, flexible PostgreSQL backup solution with configurable retention policies. This script automatically backs up all your databases (except system databases), compresses them, and manages old backups based on your retention rules.

## Features

- ✓ Backs up all databases automatically (excludes system databases)
- ✓ Automatic gzip compression
- ✓ Flexible retention policies per backup type
- ✓ Timestamped backups and logs
- ✓ Automatic cleanup of old backups and logs
- ✓ Self-contained script (auto-detects its own location)
- ✓ Easy to deploy across multiple servers
- ✓ Secure credential management via `.env` file

## TL;DR - Quick Setup

```bash
# 1. Clone to recommended location
sudo git clone <your-repo-url> /opt/postgres-backups
cd /opt/postgres-backups

# 2. Configure credentials
sudo cp env.sample .env
sudo nano .env  # Add your DB credentials

# 3. Set permissions
sudo chmod 700 backup.sh
sudo chmod 600 .env

# 4. Test it
sudo ./backup.sh manual 7

# 5. Setup crontab (as root)
sudo crontab -e
# Then paste this:
```

**Copy-paste into crontab (Recommended Strategy):**
```bash
# PostgreSQL Backups - /opt/postgres-backups
# Hourly (every hour, retain 7 days), Weekly (Sunday, retain 30 days), Monthly (1st, retain 1 year)
0 * * * * /opt/postgres-backups/backup.sh hourly 7 >/dev/null 2>&1
0 0 * * 0 /opt/postgres-backups/backup.sh weekly 30 >/dev/null 2>&1
0 0 1 * * /opt/postgres-backups/backup.sh monthly 365 >/dev/null 2>&1
```

Done! ✓ Your databases will now backup automatically.

---

## Installation Location

For Linux systems, the recommended installation paths are:

| Path | Purpose | User |
|------|---------|------|
| `/opt/postgres-backups` | **Recommended** - System-wide, production use | root |
| `/usr/local/bin/postgres-backups` | Alternative system-wide location | root |
| `~/postgres-backups` | Personal/development use | regular user |

**Best Practice:** Use `/opt/postgres-backups` for production servers as it's the standard location for optional/add-on software packages.

## Quick Start

1. **Clone the repository:**
```bash
# Recommended for production
sudo git clone <your-repo-url> /opt/postgres-backups
cd /opt/postgres-backups
```

Or for personal use:
```bash
# For development/testing
git clone <your-repo-url> ~/postgres-backups
cd ~/postgres-backups
```

2. **Create and configure `.env` file:**
```bash
cp env.sample .env
nano .env
```

Example `.env` configuration:
```bash
DB_USER=postgres
DB_HOST=localhost
DB_PORT=5432
DB_PASSWORD=your_secure_password
EXCLUDE_DBS="postgres template0 template1"
```

3. **Set proper permissions:**
```bash
chmod 700 backup.sh
chmod 600 .env
```

4. **Test the backup:**
```bash
./backup.sh manual 7
```

Check the `manual/` directory for backup files and logs.

## Usage

The main script accepts two parameters:

```bash
./backup.sh <backup_type> <retention_days>
```

### Parameters

- **`backup_type`** (default: `manual`): Used as directory name for organizing backups
- **`retention_days`** (default: `7`): Number of days to keep backups before automatic deletion

### Examples

```bash
# Hourly backup kept for 7 days
./backup.sh hourly 7

# Daily backup kept for 30 days
./backup.sh daily 30

# Monthly backup kept for 1 year
./backup.sh monthly 365

# Weekly backup kept for 90 days
./backup.sh weekly 90

# Manual/ad-hoc backup
./backup.sh manual 7
```

## Setting Up Automated Backups

### Recommended Backup Strategy

A balanced production setup with good coverage and manageable storage:

| Frequency | Schedule | Retention | Purpose | Storage Impact |
|-----------|----------|-----------|---------|----------------|
| Hourly | Every hour (top of hour) | 7 days | Recent changes recovery | 168 backups (~1 week) |
| Weekly | Sunday at midnight | 30 days | Medium-term recovery | 4-5 backups (~1 month) |
| Monthly | 1st of month at midnight | 365 days | Long-term archives | 12 backups (~1 year) |

**Total storage:** ~184 backup sets at any given time (assuming similar database sizes)

### Crontab Configuration

#### For Production (installed in /opt/postgres-backups)

Edit root's crontab:
```bash
sudo crontab -e
```

**Copy-paste this complete configuration:**

```bash
# PostgreSQL Automated Backups - Recommended Strategy
# Script location: /opt/postgres-backups/backup.sh
# Format: minute hour day month weekday command

# Hourly backups - top of every hour, retain 7 days (168 backups)
0 * * * * /opt/postgres-backups/backup.sh hourly 7 >/dev/null 2>&1

# Weekly backups - Sunday at midnight, retain 30 days (4-5 backups)
0 0 * * 0 /opt/postgres-backups/backup.sh weekly 30 >/dev/null 2>&1

# Monthly backups - 1st of month at midnight, retain 1 year (12 backups)
0 0 1 * * /opt/postgres-backups/backup.sh monthly 365 >/dev/null 2>&1
```

#### For Development (installed in home directory)

Edit your user's crontab:
```bash
crontab -e
```

**Copy-paste this configuration (adjust path if needed):**

```bash
# PostgreSQL Automated Backups (Development)
# Script location: ~/postgres-backups/backup.sh

# Daily backups - 2 AM every day, retain 30 days
0 2 * * * ~/postgres-backups/backup.sh daily 30 >/dev/null 2>&1

# Weekly backups - Sunday at midnight, retain 90 days
0 0 * * 0 ~/postgres-backups/backup.sh weekly 90 >/dev/null 2>&1
```

#### Alternative Configurations

**Minimal Setup (Daily only):**
```bash
# Daily backup at 2 AM, keep for 30 days
0 2 * * * /opt/postgres-backups/backup.sh daily 30 >/dev/null 2>&1
```

**Aggressive Backup Strategy (More frequent):**
```bash
# Every 15 minutes, keep 3 days
*/15 * * * * /opt/postgres-backups/backup.sh frequent 3 >/dev/null 2>&1

# Daily at 2 AM, keep 60 days
0 2 * * * /opt/postgres-backups/backup.sh daily 60 >/dev/null 2>&1

# Weekly on Sunday, keep 180 days
0 0 * * 0 /opt/postgres-backups/backup.sh weekly 180 >/dev/null 2>&1

# Monthly on 1st, keep 730 days (2 years)
0 0 1 * * /opt/postgres-backups/backup.sh monthly 730 >/dev/null 2>&1
```

**Conservative Setup (Less frequent, longer retention):**
```bash
# Daily at 3 AM, keep 90 days
0 3 * * * /opt/postgres-backups/backup.sh daily 90 >/dev/null 2>&1

# Monthly on 1st at midnight, keep 5 years
0 0 1 * * /opt/postgres-backups/backup.sh monthly 1825 >/dev/null 2>&1
```

#### Verify Crontab Configuration

After saving, verify your crontab:
```bash
# View root crontab
sudo crontab -l

# View user crontab
crontab -l

# Check if cron service is running
sudo systemctl status cron     # Debian/Ubuntu
sudo systemctl status crond    # CentOS/RHEL
```

#### Quick Crontab Reference

| Schedule | Cron Expression | Command Example |
|----------|----------------|-----------------|
| Every 15 min | `*/15 * * * *` | `backup.sh frequent 3` |
| Every 30 min | `*/30 * * * *` | `backup.sh hourly 7` |
| Every hour | `0 * * * *` | `backup.sh hourly 7` |
| Daily 2 AM | `0 2 * * *` | `backup.sh daily 30` |
| Weekly (Sun) | `0 0 * * 0` | `backup.sh weekly 90` |
| Monthly (1st) | `0 0 1 * *` | `backup.sh monthly 365` |
| Twice daily | `0 2,14 * * *` | `backup.sh twicedaily 14` |

### Systemd Timer (Alternative to Cron)

If you prefer systemd timers, here's an example setup:

**`/etc/systemd/system/postgres-backup-daily.service`:**
```ini
[Unit]
Description=PostgreSQL Daily Backup
After=postgresql.service

[Service]
Type=oneshot
ExecStart=/opt/postgres-backups/backup.sh daily 30
User=root
```

**`/etc/systemd/system/postgres-backup-daily.timer`:**
```ini
[Unit]
Description=PostgreSQL Daily Backup Timer

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:
```bash
systemctl enable postgres-backup-daily.timer
systemctl start postgres-backup-daily.timer
```

## Directory Structure

After running backups, your directory structure will look like:

```
/opt/postgres-backups/
├── backup.sh                           # Main backup script
├── .env                                # Database credentials (git ignored)
├── env.sample                          # Example configuration template
├── .gitignore                          # Git ignore rules
├── README.md                           # This file
├── hourly/                             # Hourly backups directory
│   ├── backup_20260107_093000_db1.sql.gz
│   ├── backup_20260107_093000_db2.sql.gz
│   └── backup_20260107_093000.log
├── daily/                              # Daily backups directory
│   └── ...
└── monthly/                            # Monthly backups directory
    └── ...
```

**Note:** Backup directories are created automatically when first used.

## File Naming Convention

### Backup Files
```
backup_YYYYMMDD_HHMMSS_<database_name>.sql.gz
```

Example:
```
backup_20260107_143522_myapp_production.sql.gz
```

### Log Files
```
backup_YYYYMMDD_HHMMSS.log
```

Example:
```
backup_20260107_143522.log
```

## Configuration

### Environment Variables

All database configuration is stored in the `.env` file:

```bash
# Database connection settings
DB_USER=postgres          # PostgreSQL username
DB_HOST=localhost         # Database host
DB_PORT=5432             # Database port
DB_PASSWORD=secret       # Database password

# Databases to exclude from backups (space-separated)
EXCLUDE_DBS="postgres template0 template1"
```

### Excluding Databases

Add database names to `EXCLUDE_DBS` in your `.env` file:

```bash
EXCLUDE_DBS="postgres template0 template1 test_db development_db"
```

Common databases to exclude:
- `postgres` - PostgreSQL system database
- `template0`, `template1` - Template databases
- Test/development databases you don't need backed up

## Restoring Backups

### Single Database Restore

```bash
# 1. Decompress the backup
gunzip backup_20260107_093000_mydb.sql.gz

# 2. Restore to database
psql -h localhost -U postgres -d mydb < backup_20260107_093000_mydb.sql
```

### Restore to Different Database Name

```bash
# Create new database
psql -h localhost -U postgres -c "CREATE DATABASE mydb_restored;"

# Restore backup
gunzip -c backup_20260107_093000_mydb.sql.gz | psql -h localhost -U postgres -d mydb_restored
```

### List Contents Without Restoring

```bash
# View SQL content
gunzip -c backup_20260107_093000_mydb.sql.gz | less
```

## Monitoring and Logs

### Check Backup Logs

Each backup run creates a detailed log file:

```bash
# View latest hourly backup log
tail -f hourly/backup_$(ls -t hourly/backup_*.log | head -1 | xargs basename)

# Search for errors
grep -i error hourly/*.log
```

### Log Format

Logs include:
- Timestamp for each operation
- Database connection status
- Per-database backup success/failure
- File sizes of created backups
- Cleanup operations
- Summary statistics

Example log entry:
```
[2026-01-07 14:35:22] Starting database backup process - Type: daily, Retention: 30 days
[2026-01-07 14:35:23] Backing up database: myapp_production
[2026-01-07 14:35:45] ✓ Backup completed successfully: daily/backup_20260107_143522_myapp_production.sql.gz (Size: 245M)
[2026-01-07 14:35:45] Backup process completed - Success: 3, Failed: 0
```

### Set Up Monitoring (Optional)

Use monitoring tools to track backup job execution and alert on failures:
- Cronitor, Healthchecks.io, or UptimeRobot for cron monitoring
- Check log files regularly: `tail -f /opt/postgres-backups/daily/*.log`
- Monitor disk space: `df -h /opt/postgres-backups/`

## Security Best Practices

### File Permissions

```bash
# Script executable by root only
chmod 700 backup.sh

# Credentials readable by root only  
chmod 600 .env

# Backup directories (created automatically with these permissions)
chmod 700 hourly/ daily/ monthly/
```

### Credential Management

- ✓ Store credentials only in `.env` file
- ✓ `.env` is automatically excluded from git via `.gitignore`
- ✓ Never commit `.env` to version control
- ✓ Use `env.sample` as a template (without real credentials)
- ✓ Consider using PostgreSQL `.pgpass` file for additional security

### Backup Storage

For production systems, consider:
- Store backups on a separate disk/volume
- Replicate backups to remote storage (S3, rsync to remote server)
- Encrypt backups if they contain sensitive data
- Test restore procedures regularly

## Troubleshooting

### Permission Denied Error

```bash
chmod 700 /opt/postgres-backups/backup.sh
chmod 600 /opt/postgres-backups/.env
```

### "ERROR: .env file not found"

Create the `.env` file:
```bash
cp env.sample .env
nano .env
```

### Password Authentication Failed

Check your `.env` credentials:
```bash
cat .env
```

Test database connection manually:
```bash
psql -h localhost -p 5432 -U postgres -c "SELECT version();"
```

### No Backups Created

Check the log files:
```bash
cat <backup_type>/backup_*.log | tail -20
```

Common issues:
- Incorrect database credentials
- PostgreSQL not running
- Network connectivity issues (if remote host)
- Insufficient disk space

### Script Not Running in Cron

Cron runs with minimal environment. Use full paths:
```bash
# Bad
*/30 * * * * ./backup.sh hourly 7

# Good
*/30 * * * * /opt/postgres-backups/backup.sh hourly 7
```

Check cron logs:
```bash
# On most Linux systems
grep CRON /var/log/syslog

# On systems with systemd
journalctl -u cron
```

## Advanced Usage

### Remote Database Backups

The script works with remote PostgreSQL servers. Just configure in `.env`:

```bash
DB_HOST=db.example.com
DB_PORT=5432
DB_USER=backup_user
DB_PASSWORD=secure_password
```

### Custom Backup Scripts

You can create custom wrapper scripts for specialized needs:

```bash
#!/bin/bash
# custom-backup.sh - Backup with notifications

# Run backup
/opt/postgres-backups/backup.sh custom 14

# Send notification on failure
if [ $? -ne 0 ]; then
    echo "Backup failed!" | mail -s "Backup Alert" admin@example.com
fi
```

### Backup Multiple PostgreSQL Instances

Create separate installations with different `.env` files:

```bash
/opt/postgres-backups/
├── prod/
│   ├── backup.sh
│   └── .env (prod database config)
└── staging/
    ├── backup.sh
    └── .env (staging database config)
```

## How It Works

1. **Auto-detects location**: Uses `BASH_SOURCE[0]` to find its own directory
2. **Loads credentials**: Sources `.env` file from script directory
3. **Creates backup directory**: Named after backup type (e.g., `hourly/`)
4. **Connects to PostgreSQL**: Retrieves list of all databases
5. **Filters databases**: Excludes system databases and those in `EXCLUDE_DBS`
6. **Backs up each database**: Uses `pg_dump` to create SQL dumps
7. **Compresses backups**: Uses gzip to reduce storage space
8. **Cleans old backups**: Removes backup files older than retention period
9. **Cleans old logs**: Removes log files older than retention period
10. **Reports results**: Logs success/failure counts and exits with appropriate code

## Requirements

- Bash 4.0+
- PostgreSQL client tools (`psql`, `pg_dump`)
- `gzip` for compression
- `find` for cleanup operations

## Contributing

Contributions are welcome! Areas for improvement:
- Encryption support
- Cloud storage integration (S3, GCS, Azure)
- Parallel backup execution
- Backup verification
- Email notifications

## License

Free to use and modify for any purpose.

## Support

For issues or questions, please check:
1. Log files in your backup directories
2. PostgreSQL connection with `psql`
3. File permissions on script and `.env`
4. Cron logs for scheduling issues
