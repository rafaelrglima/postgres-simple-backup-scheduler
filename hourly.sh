#!/bin/bash

# Hourly backup script
# Runs every 30 minutes, keeps backups for 7 days

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/backup.sh" hourly 7

