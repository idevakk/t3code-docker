#!/usr/bin/env bash
# ==============================================================================
# Stop OpenCode Web Server
# ==============================================================================
set -e

echo "Stopping OpenCode Web server inside container..."
docker compose exec t3code-server supervisorctl stop opencode

echo ""
echo "OpenCode Web server has been stopped and port is closed."
echo "To restart it anytime, run: ./opencode-start.sh"
