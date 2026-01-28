#!/bin/bash

# Mailcow Backup Script for Production
# This script automates the backup process and rotates old backups.

# Configuration
MAILCOW_PATH="/opt/mailcow-dockerized"
BACKUP_DIR="/opt/mailcow-backups"
KEEP_BACKUPS_DAYS=7
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting Mailcow backup at $DATE..."

# Change to mailcow directory
cd "$MAILCOW_PATH" || { echo "Mailcow directory not found!"; exit 1; }

# Run the official backup script
# 'all' backs up everything including DB and volumes
export MAILCOW_BACKUP_LOCATION="$BACKUP_DIR"
./helper-scripts/backup_and_restore.sh backup all

if [ $? -eq 0 ]; then
    echo "Backup completed successfully."
else
    echo "Backup failed!"
    exit 1
fi

# Cleanup old backups
echo "Cleaning up backups older than $KEEP_BACKUPS_DAYS days..."
find "$BACKUP_DIR" -type d -mtime +$KEEP_BACKUPS_DAYS -exec rm -rf {} +

echo "Backup process finished."
