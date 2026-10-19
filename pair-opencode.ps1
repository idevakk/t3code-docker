# ==============================================================================
# Generate OpenCode v2 Pairing Link & QR Code (PowerShell)
# Use this to pair your browser or desktop client with OpenCode v2
# ==============================================================================

Write-Host "Generating OpenCode v2 pairing URL from container..." -ForegroundColor Cyan
docker compose exec -it -u coder t3code-server opencode pair $args
