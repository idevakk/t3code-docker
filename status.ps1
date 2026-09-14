# ==============================================================================
# Check Service and Resource Status (PowerShell)
# ==============================================================================

Write-Host "=== Container Status ===" -ForegroundColor Cyan
docker compose ps

Write-Host "`n=== Internal Services (Supervisor) ===" -ForegroundColor Cyan
docker compose exec t3code-server supervisorctl status

Write-Host "`n=== Current Resource Usage ===" -ForegroundColor Cyan
docker stats --no-stream t3code-server
