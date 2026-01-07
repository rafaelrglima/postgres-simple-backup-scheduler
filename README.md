# PostgreSQL Backup Scripts

Automated PostgreSQL database backup solution with configurable retention policies.

## Features

- Backs up all databases (except system databases)
- Automatic compression (gzip)
- Configurable retention policies
- Timestamped backups and logs
- Automatic cleanup of old backups
- Easy to deploy across multiple servers

## Installation

1. Clone this repository:
```bash
git clone <your-repo-url> /var/www/backups
cd /var/www/backups
```

2. Create your `.env` file:
```bash
cp .env.example .env
nano .env
```

3. Configure your database credentials in `.env`:
```bash
DB_USER=postgres
DB_HOST=localhost
DB_PORT=5432
DB_PASSWORD=your_secure_password
```

4. Set permissions:
```bash
chmod 700 *.sh
chmod 600 .env
```

5. Test the backup:
```bash
./hourly.sh
```

## Available Schedules

### Hourly Backups
- **Script**: `hourly.sh`
- **Retention**: 7 days
- **Recommended cron**: `*/30 * * * *` (every 30 minutes)

### Daily Backups
- **Script**: `daily.sh`
- **Retention**: 30 days
- **Recommended cron**: `0 2 * * *` (2 AM daily)

### Monthly Backups
- **Script**: `monthly.sh`
- **Retention**: 365 days (1 year)
- **Recommended cron**: `0 0 1 * *` (midnight on 1st of each month)

## Crontab Configuration

Edit root's crontab:
```bash
crontab -e
```

Add your desired schedule:
```bash
# Hourly backups (every 30 minutes)
*/30 * * * * /var/www/backups/hourly.sh

# Daily backups (2 AM)
0 2 * * * /var/www/backups/daily.sh

# Monthly backups (1st of month at midnight)
0 0 1 * * /var/www/backups/monthly.sh
```

## Directory Structure

```
/var/www/backups/
├── backup.sh              # Main backup script
├── hourly.sh              # Hourly schedule wrapper
├── daily.sh               # Daily schedule wrapper
├── monthly.sh             # Monthly schedule wrapper
├── .env                   # Database credentials (git ignored)
├── .env.example           # Example configuration
├── .gitignore             # Git ignore rules
├── README.md              # This file
├── hourly/                # Hourly backups (7 days retention)
├── daily/                 # Daily backups (30 days retention)
└── monthly/               # Monthly backups (365 days retention)
```

## Custom Schedules

You can create custom schedules by creating new wrapper scripts:

```bash
#!/bin/bash
# weekly.sh - Weekly backups kept for 90 days

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/backup.sh" weekly 90
```

Then add to crontab:
```bash
0 0 * * 0 /var/www/backups/weekly.sh  # Every Sunday at midnight
```

## Backup File Naming

Backups are named with the format:
```
backup_YYYYMMDD_HHMMSS_<database_name>.sql.gz
```

Example:
```
backup_20260107_093000_alacritylss.sql.gz
```

## Logs

Each backup run creates a log file in the same directory as the backups:
```
backup_YYYYMMDD_HHMMSS.log
```

Logs are automatically cleaned up based on the retention policy.

## Excluding Databases

To exclude specific databases from backups, edit the `EXCLUDE_DBS` variable in your `.env` file:

```bash
EXCLUDE_DBS="postgres template0 template1 test_db"
```

## Restoring a Backup

To restore a backup:

```bash
# Decompress
gunzip backup_20260107_093000_mydb.sql.gz

# Restore
psql -U postgres -d mydb < backup_20260107_093000_mydb.sql
```

## Security

- `.env` file contains credentials - keep permissions at `600` (root only)
- All scripts should have `700` permissions (root only)
- Backup directories are created with `700` permissions
- `.env` is excluded from git via `.gitignore`

## Troubleshooting

### Permission Denied
```bash
chmod 700 /var/www/backups/*.sh
chmod 600 /var/www/backups/.env
```

### Password Prompt
Make sure `.env` file exists and contains correct credentials.

### No Backups Created
Check the log files in the backup directory for errors.

## License

Free to use and modify.

