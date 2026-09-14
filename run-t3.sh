#!/usr/bin/env bash
set -e

cd /workspace || exit 1

export HOME="/home/coder"
export USER="coder"
export PATH="/home/coder/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

T3_HOST="${T3CODE_HOST:-0.0.0.0}"
T3_PORT="${T3CODE_PORT:-3773}"

echo "[T3 Code] Starting T3 Code server on ${T3_HOST}:${T3_PORT}..."
exec t3 serve --host "${T3_HOST}" --port "${T3_PORT}"
