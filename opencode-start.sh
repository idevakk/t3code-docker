#!/usr/bin/env bash
# ==============================================================================
# Start OpenCode Web Server On-Demand
# ==============================================================================
set -e

echo "Starting OpenCode Web server inside container..."
docker compose exec t3code-server supervisorctl start opencode

echo ""
echo "=== OpenCode Web is now active! ==="
echo "Access URL: http://localhost:${OPENCODE_PORT:-4096}"
echo "To stop it anytime, run: ./opencode-stop.sh"
