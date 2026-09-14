FROM node:22-bookworm-slim

LABEL maintainer="t3code-docker"
LABEL description="Secure Docker environment for T3 Code Server and OpenCode Web with Agent Isolation"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required system packages:
# - openssh-server: Remote SSH access for T3 Code Desktop & remote shells
# - supervisor: Reliable process manager to keep SSH, T3 Code, and OpenCode alive
# - git, curl, wget, ca-certificates: Required for cloning repos, installing tools
# - build-essential (gcc, g++, make), python3: CRITICAL for node-pty and native addon builds required by T3 Code
# - procps, net-tools, iproute2: Process monitoring and network diagnostic tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    supervisor \
    git \
    curl \
    wget \
    ca-certificates \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    procps \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install T3 Code CLI, OpenCode AI, and Claude Code globally
# - t3: Official T3 Code server & harness CLI (pingdotgg/t3code)
# - opencode-ai: Official SST/Anomaly OpenCode agent with web server support
# - @anthropic-ai/claude-code: Official Anthropic Claude Code CLI
RUN npm install -g --no-audit --no-fund \
    t3@latest \
    opencode-ai@latest \
    @anthropic-ai/claude-code@latest

# Setup non-root user 'coder' (UID 1000, GID 1000)
# Running all AI coding agents as non-root prevents host and system privilege escalation
# Official node base images already have a 'node' user with UID 1000; rename it to 'coder'
RUN if id -u node >/dev/null 2>&1; then \
        usermod -l coder -d /home/coder -m node && \
        groupmod -n coder node; \
    else \
        groupadd -g 1000 coder && \
        useradd -u 1000 -g coder -m -s /bin/bash coder; \
    fi

# Prepare directory structure
RUN mkdir -p /workspace /run/sshd /var/log/supervisor /etc/ssh/ssh_host_keys && \
    chown -R coder:coder /workspace /home/coder && \
    chmod 755 /run/sshd

# Harden SSH configuration
# - Restrict SSH access strictly to the 'coder' user
# - Disable root login entirely
# - Enable public key and password authentication
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    echo "AllowUsers coder" >> /etc/ssh/sshd_config && \
    echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config && \
    echo "ClientAliveCountMax 5" >> /etc/ssh/sshd_config

# Copy supervisor configuration and runner scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY run-t3.sh /usr/local/bin/run-t3.sh
COPY run-opencode.sh /usr/local/bin/run-opencode.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/run-t3.sh \
             /usr/local/bin/run-opencode.sh \
             /usr/local/bin/entrypoint.sh

# Work directory
WORKDIR /workspace

# Exposed ports:
# - 22: OpenSSH server (maps to host SSH_PORT, e.g. 2222)
# - 3773: T3 Code Server (maps to host T3_PORT, e.g. 3773)
# - 4096: OpenCode Web UI (maps to host OPENCODE_PORT, e.g. 4096)
EXPOSE 22 3773 4096

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
