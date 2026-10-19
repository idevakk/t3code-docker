#!/usr/bin/env bash
# ==============================================================================
# Generate OpenCode v2 Pairing Link & QR Code
# Use this to pair your browser or desktop client with OpenCode v2
# ==============================================================================

echo "Generating OpenCode v2 pairing URL from container..."
docker compose exec -it -u coder t3code-server opencode pair "$@"
