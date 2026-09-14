# ==============================================================================
# Backup Workspace and T3 Code / OpenCode State (PowerShell)
# ==============================================================================

$BackupDir = ".\backups"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = "$BackupDir\t3code_backup_$Timestamp.zip"

if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

Write-Host "Creating persistent backup of workspace and T3 database/config..." -ForegroundColor Cyan

# Compress workspace and data directories
$ItemsToCompress = @()
if (Test-Path ".\workspace") { $ItemsToCompress += ".\workspace" }
if (Test-Path ".\data") { $ItemsToCompress += ".\data" }

if ($ItemsToCompress.Count -gt 0) {
    Compress-Archive -Path $ItemsToCompress -DestinationPath $BackupFile -Force
    Write-Host "Backup completed successfully!" -ForegroundColor Green
    Write-Host "File: $BackupFile" -ForegroundColor Green
} else {
    Write-Host "No workspace or data directories found to back up." -ForegroundColor Yellow
}
