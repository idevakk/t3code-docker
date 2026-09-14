#!/usr/bin/env bash
# ==============================================================================
# Check Service and Resource Status
# ==============================================================================

echo "=== Container Status ==="
docker compose ps

echo ""
echo "=== Internal Services (Supervisor) ==="
docker compose exec t3code-server supervisorctl status

echo ""
echo "=== Current Resource Usage ==="
docker stats --no-stream t3code-server
