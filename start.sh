#!/usr/bin/env bash
# ==============================================================================
# Build and Start T3 Code & OpenCode Docker Environment
# ==============================================================================
set -e

if [ ! -f .env ]; then
    echo "No .env found. Copying .env.example to .env..."
    cp .env.example .env
    echo "Please review and customize .env credentials."
fi

echo "Building and starting container in background..."
docker compose up -d --build

echo ""
echo "=== Services successfully started! ==="
echo "SSH Server:      port ${SSH_PORT:-2222} (user: coder)"
echo "T3 Code Server:  http://localhost:${T3_PORT:-3773}"
echo "OpenCode Web UI: http://localhost:${OPENCODE_PORT:-4096}"
echo ""
echo "To generate a T3 Code pairing URL/QR code, run:  ./pair-t3.sh"
echo "To link with https://app.t3.codes/, run:         ./connect-t3.sh"
echo "To check status & resources, run:                ./status.sh"
