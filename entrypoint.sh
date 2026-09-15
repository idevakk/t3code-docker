#!/usr/bin/env bash
set -e

echo "=== Initializing T3 Code & OpenCode Container ==="

# 1. SSH Host Keys Persistence
HOST_KEY_DIR="/etc/ssh/ssh_host_keys"
mkdir -p "$HOST_KEY_DIR"

if [ ! -f "$HOST_KEY_DIR/ssh_host_ed25519_key" ]; then
    echo "[SSH] Generating new SSH host keys in $HOST_KEY_DIR..."
    ssh-keygen -t ed25519 -f "$HOST_KEY_DIR/ssh_host_ed25519_key" -N "" < /dev/null
    ssh-keygen -t rsa -b 4096 -f "$HOST_KEY_DIR/ssh_host_rsa_key" -N "" < /dev/null
fi

cp "$HOST_KEY_DIR"/ssh_host_* /etc/ssh/
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

mkdir -p /run/sshd
chmod 755 /run/sshd

# 2. Skeleton & Directory Initialization for Persistent Home
if [ ! -f /home/coder/.bashrc ]; then
    echo "[Init] Populating default shell profile into persistent home..."
    cp /etc/skel/.bashrc /home/coder/.bashrc 2>/dev/null || touch /home/coder/.bashrc
    cp /etc/skel/.profile /home/coder/.profile 2>/dev/null || true
fi

# Ensure T3 Code and OpenCode persistent state directories exist
mkdir -p /home/coder/.t3/userdata
mkdir -p /home/coder/.config/opencode
mkdir -p /home/coder/.local/share/opencode
mkdir -p /home/coder/.ssh
touch /home/coder/.ssh/authorized_keys

# 3. Configure 'coder' User Credentials
CODER_PASS="${CODER_PASSWORD:-coder_secure_pass_2026}"
echo "coder:${CODER_PASS}" | chpasswd
echo "[Auth] 'coder' user password configured."

# 4. Setup SSH Authorized Keys
if [ -n "$SSH_PUBLIC_KEY" ]; then
    if ! grep -qxF "$SSH_PUBLIC_KEY" /home/coder/.ssh/authorized_keys; then
        echo "$SSH_PUBLIC_KEY" >> /home/coder/.ssh/authorized_keys
        echo "[SSH] Added SSH_PUBLIC_KEY to /home/coder/.ssh/authorized_keys."
    fi
fi

chmod 700 /home/coder/.ssh
chmod 600 /home/coder/.ssh/authorized_keys

# 5. Git Configuration for Coding Agents (Safe Directory & Identity)
# Prevents 'fatal: detected dubious ownership in repository' when mounting host volumes
su - coder -c "git config --global --add safe.directory '*'"
su - coder -c "git config --global user.name '${GIT_USER_NAME:-iDevakk}'"
su - coder -c "git config --global user.email '${GIT_USER_EMAIL:-219866223+idevakk@users.noreply.github.com}'"
su - coder -c "git config --global init.defaultBranch main"

# Authenticate GitHub CLI (gh) if token is provided
GH_AUTH_TOKEN="${GITHUB_TOKEN:-$GH_TOKEN}"
if [ -n "$GH_AUTH_TOKEN" ]; then
    echo "$GH_AUTH_TOKEN" | su - coder -c "gh auth login --with-token 2>/dev/null || true"
    echo "[GitHub] GitHub CLI (gh) authenticated via token."
fi

# 6. Privilege Escalation / Sudo Configuration
if [ "$ENABLE_SUDO" = "true" ] || [ "$ENABLE_SUDO" = "1" ] || [ "$ENABLE_SUDO" = "yes" ]; then
    echo "[Security Notice] Passwordless sudo ENABLED for 'coder' (allows agents & tools to install packages dynamically)."
    echo "coder ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder
    chmod 0440 /etc/sudoers.d/coder
else
    echo "[Security Hardening] Sudo is DISABLED for 'coder'. Coding agents cannot escalate to root."
    rm -f /etc/sudoers.d/coder
fi

# 7. Seed Initial Workspace Documentation if Empty
if [ -d /workspace ] && [ -z "$(ls -A /workspace 2>/dev/null)" ]; then
    cat << 'EOF' > /workspace/WORKSPACE_PERSISTENCE.md
# Workspace & T3 Code Persistence

All projects, git repositories, and branches created here are **persistent across deployments**.
- Worktree directories created by T3 Code will remain intact.
- Agent sessions and thread history are stored in `/home/coder/.t3/state.sqlite` and persist alongside your code.
- To clone a new project, run: `git clone <repo-url>` inside this `/workspace` directory.
EOF
fi

# 8. Fix Workspace and Home Directory Ownership
chown -R coder:coder /workspace
chown -R coder:coder /home/coder

# 9. Ensure Environment Variables are Accessible in Interactive SSH Sessions
BASHRC="/home/coder/.bashrc"
touch "$BASHRC"

# Clean previous auto-generated blocks
sed -i '/# BEGIN T3_DOCKER_ENV/,/# END T3_DOCKER_ENV/d' "$BASHRC"

cat << 'EOF' >> "$BASHRC"
# BEGIN T3_DOCKER_ENV
export PATH="/home/coder/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export T3CODE_HOST="${T3CODE_HOST:-0.0.0.0}"
export T3CODE_PORT="${T3CODE_PORT:-3773}"
export OPENCODE_HOSTNAME="${OPENCODE_HOSTNAME:-0.0.0.0}"
export OPENCODE_PORT="${OPENCODE_PORT:-4096}"
[ -n "$ANTHROPIC_API_KEY" ] && export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
[ -n "$OPENAI_API_KEY" ] && export OPENAI_API_KEY="$OPENAI_API_KEY"
[ -n "$GEMINI_API_KEY" ] && export GEMINI_API_KEY="$GEMINI_API_KEY"
[ -n "$GITHUB_TOKEN" ] && export GITHUB_TOKEN="$GITHUB_TOKEN"
[ -n "$GH_TOKEN" ] && export GH_TOKEN="$GH_TOKEN"
# END T3_DOCKER_ENV
EOF
# 10. OpenCode Web Auto-Start Control
SUPERVISOR_CONF="/etc/supervisor/conf.d/supervisord.conf"
if [ "$ENABLE_OPENCODE_WEB" = "true" ] || [ "$ENABLE_OPENCODE_WEB" = "1" ] || [ "$ENABLE_OPENCODE_WEB" = "yes" ]; then
    echo "[OpenCode] ENABLE_OPENCODE_WEB=true: Enabling auto-start for OpenCode Web server."
    sed -i '/\[program:opencode\]/,/\[/ s/autostart=false/autostart=true/' "$SUPERVISOR_CONF"
else
    echo "[OpenCode] OpenCode Web is OFF by default (ENABLE_OPENCODE_WEB=false)."
    echo "[OpenCode] To launch on demand: run './opencode-start.sh' or 'supervisorctl start opencode'."
    sed -i '/\[program:opencode\]/,/\[/ s/autostart=true/autostart=false/' "$SUPERVISOR_CONF"
fi

echo "=== Container Initialization Complete. Launching Services ==="
exec "$@"
