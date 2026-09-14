#!/usr/bin/env bash
# ==============================================================================
# Generate a T3 Code Pairing Link & QR Code
# Use this to pair your mobile phone, laptop, or app.t3.codes
# ==============================================================================

echo "Generating fresh T3 Code pairing URL & QR code from container..."
docker compose exec -it -u coder t3code-server t3 pair
