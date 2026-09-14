# ==============================================================================
# Restore Workspace and T3 Code / OpenCode State (PowerShell)
# Usage: .\restore.ps1 -BackupFile backups\t3code_backup_YYYYMMDD_HHMMSS.zip
# ==============================================================================
param (
    [string]$BackupFile
)

if (-not $BackupFile -or -not (Test-Path $BackupFile)) {
    Write-Host "Usage: .\restore.ps1 -BackupFile <path-to-backup.zip>" -ForegroundColor Yellow
    Write-Host "Available backups in .\backups:" -ForegroundColor Cyan
    Get-ChildItem .\backups\*.zip -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime
    exit
}

Write-Host "Stopping containers before restore..." -ForegroundColor Cyan
docker compose down

Write-Host "Restoring from $BackupFile..." -ForegroundColor Cyan
Expand-Archive -Path $BackupFile -DestinationPath ".\" -Force

Write-Host "Restore completed. Restarting container..." -ForegroundColor Green
docker compose up -d
Write-Host "All workspace files, T3 database, and OpenCode configs have been restored." -ForegroundColor Green
