#!/usr/bin/env bash
# ==============================================================================
# Initiate T3 Connect Tunnel (for https://app.t3.codes/)
# ==============================================================================

echo "Starting T3 Connect authorization inside container..."
echo "Open the printed URL in your browser to authorize your T3 account."
docker compose exec -it -u coder t3code-server t3 connect
