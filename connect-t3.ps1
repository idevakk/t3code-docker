# ==============================================================================
# Initiate T3 Connect Tunnel (PowerShell) (for https://app.t3.codes/)
# ==============================================================================

Write-Host "Starting T3 Connect authorization inside container..." -ForegroundColor Cyan
Write-Host "Open the printed URL in your browser to authorize your T3 account." -ForegroundColor Yellow
docker compose exec -it -u coder t3code-server t3 connect
