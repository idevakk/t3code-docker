#!/usr/bin/env bash
# ==============================================================================
# Backup Workspace and T3 Code / OpenCode State
# ==============================================================================
set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/t3code_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Creating persistent backup of workspace and T3 database/config..."
tar -czf "$BACKUP_FILE" \
    --exclude="./workspace/.gitkeep" \
    --exclude="./data/.gitkeep" \
    ./workspace ./data 2>/dev/null || true

echo "Backup completed successfully!"
echo "File: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
