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

# 5b. Pre-configure Claude Code to bypass interactive onboarding / login prompts
python3 -c "
import json, os
claude_file = '/home/coder/.claude.json'
data = {}
if os.path.exists(claude_file):
    try:
        with open(claude_file, 'r') as f:
            data = json.load(f)
    except Exception:
        data = {}

data['hasCompletedOnboarding'] = True
data['autoUpdaterStatus'] = 'disabled'

anthropic_model = os.environ.get('ANTHROPIC_MODEL', '').strip()
if anthropic_model:
    data['customModel'] = anthropic_model

with open(claude_file, 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
chown coder:coder /home/coder/.claude.json 2>/dev/null || true
chmod 600 /home/coder/.claude.json 2>/dev/null || true
echo "[Claude Code] Auto-login onboarding pre-configured."

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

# 9. Ensure Environment Variables are Accessible Across All Shells (SSH, Root, Coder)
BASHRC="/home/coder/.bashrc"
ROOT_BASHRC="/root/.bashrc"
PROFILE_D="/etc/profile.d/t3code_env.sh"
ETC_ENV="/etc/environment"

touch "$BASHRC" "$ROOT_BASHRC" "$PROFILE_D" "$ETC_ENV"

# Generate system-wide profile export (sourced by all login shells: ssh, bash -l, su)
cat << 'EOF_PROFILE_HEADER' > "$PROFILE_D"
# System-wide Environment Variables for T3 Code, OpenCode & Claude Code
export PATH="/home/coder/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
EOF_PROFILE_HEADER

# Safely append runtime values from entrypoint into profile.d and /etc/environment
export_var() {
    local var_name="$1"
    local var_val="$2"
    if [ -n "$var_val" ]; then
        local safe_val
        safe_val=$(printf '%s' "$var_val" | sed 's/\\/\\\\/g; s/"/\\"/g')
        echo "export ${var_name}=\"${safe_val}\"" >> "$PROFILE_D"
        sed -i "/^${var_name}=/d" "$ETC_ENV" 2>/dev/null || true
        echo "${var_name}=\"${safe_val}\"" >> "$ETC_ENV"
    fi
}

export_var "T3CODE_HOST" "${T3CODE_HOST:-0.0.0.0}"
export_var "T3CODE_PORT" "${T3CODE_PORT:-3773}"
export_var "OPENCODE_HOSTNAME" "${OPENCODE_HOSTNAME:-0.0.0.0}"
export_var "OPENCODE_PORT" "${OPENCODE_PORT:-4096}"
export_var "ANTHROPIC_API_KEY" "$ANTHROPIC_API_KEY"
export_var "ANTHROPIC_BASE_URL" "$ANTHROPIC_BASE_URL"
export_var "ANTHROPIC_MODEL" "$ANTHROPIC_MODEL"
export_var "OPENAI_API_KEY" "$OPENAI_API_KEY"
export_var "OPENAI_BASE_URL" "$OPENAI_BASE_URL"
export_var "GEMINI_API_KEY" "$GEMINI_API_KEY"
export_var "GITHUB_TOKEN" "$GITHUB_TOKEN"
export_var "GH_TOKEN" "$GH_TOKEN"

chmod 644 "$PROFILE_D"

# Prepend to the top of .bashrc so all subshells (interactive, non-interactive, scripts) get variables
for rc_file in "$BASHRC" "$ROOT_BASHRC"; do
    sed -i '/# BEGIN T3_DOCKER_ENV/,/# END T3_DOCKER_ENV/d' "$rc_file" 2>/dev/null || true
    TMP_RC="$(mktemp)"
    cat << 'EOF' > "$TMP_RC"
# BEGIN T3_DOCKER_ENV
[ -f /etc/profile.d/t3code_env.sh ] && . /etc/profile.d/t3code_env.sh
# END T3_DOCKER_ENV
EOF
    cat "$rc_file" >> "$TMP_RC" 2>/dev/null || true
    mv "$TMP_RC" "$rc_file"
done

# Ensure correct file permissions
chown -R coder:coder /home/coder
chmod 644 /home/coder/.bashrc 2>/dev/null || true
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
