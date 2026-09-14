# ==============================================================================
# Stop OpenCode Web Server (PowerShell)
# ==============================================================================

Write-Host "Stopping OpenCode Web server inside container..." -ForegroundColor Cyan
docker compose exec t3code-server supervisorctl stop opencode

Write-Host "`nOpenCode Web server has been stopped and port is closed." -ForegroundColor Green
Write-Host "To restart it anytime, run: .\opencode-start.ps1" -ForegroundColor Yellow
