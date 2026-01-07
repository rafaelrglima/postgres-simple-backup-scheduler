#!/bin/bash

# Daily backup script
# Runs once per day, keeps backups for 30 days

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/backup.sh" daily 30

