# Deploying T3 Code & OpenCode on Dokploy

Yes, this setup runs on **[Dokploy](https://dokploy.com/)** smoothly! 

This guide outlines the exact steps and considerations to ensure zero-downtime persistence and automatic HTTPS SSL via Dokploy's Traefik reverse proxy.

---

## 🔑 Key Dokploy Considerations

| Feature | How Dokploy Handles It | Our Solution |
| :--- | :--- | :--- |
| **Data Persistence** | Dokploy pulls code to an internal folder on each deployment. Host relative paths (like `./workspace`) risk being overwritten during git checkouts. | Use **Named Docker Volumes** (`t3code_dokploy_workspace`, `t3code_dokploy_home`). They are managed by Docker in `/var/lib/docker/volumes/` and **never get wiped** by Dokploy deployments. |
| **HTTPS Web UI** | Dokploy manages Traefik on port 80/443 with automated Let's Encrypt certificates. | We connect the container to `dokploy-network`. You can assign custom domains (e.g. `opencode.yourdomain.com`) directly in the Dokploy UI. |
| **SSH Access (Port 2222)** | Traefik only proxies HTTP/HTTPS by default. | Port `2222:22` is exposed directly to the host network via `ports:`. T3 Code desktop connects to `coder@your-server-ip -p 2222` directly. |
| **Security Hardening** | Dokploy passes standard Docker security options to the host engine. | `no-new-privileges: true` and capability drops work out-of-the-box on Dokploy. |

---

## 🚀 Step-by-Step Deployment on Dokploy

### Step 1: Create a Compose Application in Dokploy
1. Log into your **Dokploy Dashboard**.
2. Go to your Project / Environment.
3. Click **Create Service** → Select **Compose**.
4. Name your service (e.g. `t3code-stack`).

---

### Step 2: Configure Source Code & Compose File
Choose one of two methods:

#### Method A: Git Repository (Recommended)
1. In the **General** tab, set **Source Type** to **Git**.
2. Enter your repository URL (where you pushed this code).
3. Set **Branch** to `main`.
4. Set **Compose Path** to:
   ```text
   docker-compose.dokploy.yml
   ```

#### Method B: Raw Docker Compose
1. Set **Source Type** to **Docker Compose**.
2. Copy the contents of [`docker-compose.dokploy.yml`](./docker-compose.dokploy.yml) and paste them into the compose editor in Dokploy.

---

### Step 3: Add Environment Variables in Dokploy
Navigate to the **Environment** tab in your Dokploy service and add your credentials:

```bash
CODER_PASSWORD=your_strong_ssh_password
OPENCODE_SERVER_PASSWORD=your_strong_web_password
SSH_PORT=2222
T3_PORT=3773
OPENCODE_PORT=4096
ENABLE_OPENCODE_WEB=false
ENABLE_SUDO=false
CPU_LIMIT=4.0
MEMORY_LIMIT=8G
PIDS_LIMIT=500
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=you@example.com

# Optional API Keys:
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GEMINI_API_KEY=
```

---

### Step 4: Configure Domains & HTTPS (Traefik)
In Dokploy, you can give your web services clean HTTPS domains:

1. Go to the **Domains** tab in your Dokploy application.
2. Click **Add Domain**:
   - **For OpenCode Web:**
     - **Domain:** `opencode.yourdomain.com`
     - **Service:** `t3code-server`
     - **Container Port:** `4096`
     - **HTTPS:** Enabled (Let's Encrypt will automatically issue an SSL certificate)
   - **For T3 Code Server (optional):**
     - **Domain:** `t3.yourdomain.com`
     - **Service:** `t3code-server`
     - **Container Port:** `3773`
     - **HTTPS:** Enabled

---

### Step 5: Configure VPS Firewall for SSH
Because Traefik does not proxy SSH, verify that your VPS firewall (UFW or cloud security group on Hetzner, AWS, DigitalOcean) allows inbound traffic on port `2222`:

```bash
# On your VPS terminal:
sudo ufw allow 2222/tcp
```

---

### Step 6: Deploy
Click **Deploy** in Dokploy!

Dokploy will:
1. Build the Docker image (installing Node 22, T3 Code, OpenCode, Supervisor, and OpenSSH).
2. Create the persistent Docker volumes.
3. Attach the container to `dokploy-network`.
4. Launch the services under Supervisor.

---

## 💻 Connecting After Dokploy Deployment

### 1. Connecting T3 Code Desktop App (via SSH)
In your laptop's T3 Code desktop app:
- **Host:** `<your-vps-ip>` (or your VPS hostname)
- **Port:** `2222`
- **User:** `coder`
- **Password:** The `CODER_PASSWORD` set in Dokploy.

### 2. Accessing OpenCode Web (via HTTPS)
Open your browser to:
```
https://opencode.yourdomain.com
```
Enter your `OPENCODE_SERVER_PASSWORD` to log in.

### 3. Pairing with https://app.t3.codes/
In the Dokploy UI, go to the **Terminal / Exec** tab of `t3code-server` (or SSH into your VPS) and run:
```bash
docker exec -it -u coder t3code-server t3 connect
```
Open the printed link to sign in with your T3 account. Your Dokploy container is now permanently linked to your T3 Code cloud profile!

---

## 🔄 Verified Persistence Guarantee
When you click **Redeploy** in Dokploy or push new code to your Git repo:
- Dokploy recreates the container.
- Docker re-attaches the existing `t3code_dokploy_workspace` and `t3code_dokploy_home` volumes.
- All repositories, Git branches, T3 SQLite database (`state.sqlite`), OpenCode configurations, and SSH keys remain **100% intact**.
