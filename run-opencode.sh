#!/usr/bin/env bash
set -e

cd /workspace || exit 1

export HOME="/home/coder"
export USER="coder"
export PATH="/home/coder/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

OPENCODE_HOST="${OPENCODE_HOSTNAME:-0.0.0.0}"
OPENCODE_LISTEN_PORT="${OPENCODE_PORT:-4096}"

if [ -n "$OPENCODE_SERVER_PASSWORD" ]; then
  export OPENCODE_SERVER_PASSWORD="$OPENCODE_SERVER_PASSWORD"
  echo "[OpenCode] Password protection enabled."
fi

echo "[OpenCode] Starting OpenCode web server on ${OPENCODE_HOST}:${OPENCODE_LISTEN_PORT}..."
exec opencode web --hostname "${OPENCODE_HOST}" --port "${OPENCODE_LISTEN_PORT}"
