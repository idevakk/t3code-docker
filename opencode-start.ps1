# ==============================================================================
# Start OpenCode Web Server On-Demand (PowerShell)
# ==============================================================================

Write-Host "Starting OpenCode Web server inside container..." -ForegroundColor Cyan
docker compose exec t3code-server supervisorctl start opencode

Write-Host "`n=== OpenCode Web is now active! ===" -ForegroundColor Green
Write-Host "Access URL: http://localhost:4096"
Write-Host "To stop it anytime, run: .\opencode-stop.ps1" -ForegroundColor Yellow
