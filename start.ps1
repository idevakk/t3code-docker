# ==============================================================================
# Build and Start T3 Code & OpenCode Docker Environment (PowerShell)
# ==============================================================================

if (!(Test-Path .env)) {
    Write-Host "No .env found. Copying .env.example to .env..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "Please review and customize .env credentials." -ForegroundColor Yellow
}

Write-Host "Building and starting container in background..." -ForegroundColor Cyan
docker compose up -d --build

Write-Host "`n=== Services successfully started! ===" -ForegroundColor Green
Write-Host "SSH Server:      port 2222 (user: coder)"
Write-Host "T3 Code Server:  http://localhost:3773"
Write-Host "OpenCode Web UI: http://localhost:4096"
Write-Host "`nTo generate a T3 Code pairing URL/QR code, run:  .\pair-t3.ps1" -ForegroundColor Yellow
Write-Host "To link with https://app.t3.codes/, run:         .\connect-t3.ps1" -ForegroundColor Yellow
Write-Host "To check status & resources, run:                .\status.ps1" -ForegroundColor Yellow
