#!/bin/bash

# Monthly backup script
# Runs on the 1st of each month, keeps backups for 365 days (1 year)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/backup.sh" monthly 365

