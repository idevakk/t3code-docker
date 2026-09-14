# ==============================================================================
# Generate a T3 Code Pairing Link & QR Code (PowerShell)
# Use this to pair your mobile phone, laptop, or app.t3.codes
# ==============================================================================

Write-Host "Generating fresh T3 Code pairing URL & QR code from container..." -ForegroundColor Cyan
docker compose exec -it -u coder t3code-server t3 pair
