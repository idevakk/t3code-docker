#!/usr/bin/env bash
# ==============================================================================
# Restore Workspace and T3 Code / OpenCode State
# Usage: ./restore.sh backups/t3code_backup_YYYYMMDD_HHMMSS.tar.gz
# ==============================================================================
set -e

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "Usage: ./restore.sh <path-to-backup.tar.gz>"
    echo "Available backups:"
    ls -lh ./backups/*.tar.gz 2>/dev/null || echo "No backups found."
    exit 1
fi

echo "Stopping containers before restore..."
docker compose down

echo "Restoring from $BACKUP_FILE..."
tar -xzf "$BACKUP_FILE" -C ./

echo "Restore completed. Restarting container..."
docker compose up -d
echo "All workspace files, T3 database, and OpenCode configs have been restored."
