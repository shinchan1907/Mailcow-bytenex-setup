# Mailcow Dockerized Setup for ByteNex

This repository contains the configuration and documentation for self-hosting **Mailcow** on AWS Lightsail for the organization **ByteNex**.

## 🚀 Domain Information
- **Mail Server Hostname:** `mail.bytenex.io`
- **Primary Email Domains:** 
  - `arogyamayurveda.com`
  - `arogyamshop.com`
  - (and others)

---

## 🏗️ Deployment Steps (AWS Lightsail)

### 1. Instance Selection
- Use **Ubuntu 22.04 LTS**.
- **Instance Size:** At least **4 GB RAM / 2 vCPUs** (Lightsail $20/mo or $40/mo plan).
- **Static IP:** Always attach a Static IP to your instance.

### 2. Critical DNS & Networking (Cloudflare)

#### A. Cloudflare Proxy Settings (EXTREMELY IMPORTANT)
Since you are using Cloudflare, you must configure your DNS records to be **DNS Only (Grey Cloud)**. 
- **Why?** Cloudflare's standard proxy (Orange Cloud) only supports HTTP/HTTPS. It will block all mail protocols (SMTP, IMAP, POP3).
- **SSL Conflict:** Mailcow handles its own SSL (Let's Encrypt) which is required for mail encryption. Cloudflare's proxy can interfere with this validation.

**Recommended Cloudflare Setup:**
- `mail.bytenex.io` -> **DNS Only** (Grey Cloud)
- All other mail-related records (MX, SPF, TXT) -> **DNS Only**

#### B. Firewall
Open these ports in the Lightsail Firewall:
- `25`, `80`, `443`, `110`, `143`, `465`, `587`, `993`, `995`, `4190`.

#### C. Reverse DNS (PTR Record) - MANDATORY
For mail delivery to work (to avoid being marked as spam):
1. Go to the Lightsail console -> **Networking** tab.
2. Edit **Reverse DNS** and set it to `mail.bytenex.io`.

### 3. System Preparation
```bash
sudo apt update && sudo apt upgrade -y
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
sudo systemctl enable --now docker
# Install Docker Compose (V2)
sudo apt install docker-compose-plugin
```

### 4. Setup Mailcow
```bash
# Workspace setup
cd /opt
sudo git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized

# 1. Ensure scripts are executable
sudo chmod +x generate_config.sh update.sh helper-scripts/*.sh

# 2. Run the configuration generator
# Enter your hostname (mail.bytenex.io) when prompted
sudo ./generate_config.sh

# 3. Copy our production scripts to the correct location
sudo mkdir -p /opt/mailcow-dockerized/scripts
# Assuming you cloned your setup repo to ~/Mailcow-bytenex-setup
sudo cp ~/Mailcow-bytenex-setup/scripts/backup_mailcow.sh /opt/mailcow-dockerized/scripts/
sudo chmod +x /opt/mailcow-dockerized/scripts/backup_mailcow.sh

# 4. Copy the production override if needed
sudo cp ~/Mailcow-bytenex-setup/docker-compose.override.yml /opt/mailcow-dockerized/
```

### 5. Memory Optimization (For 4GB RAM Instances)
If you experience crashes, disable ClamAV and Solr in `mailcow.conf`:
```bash
# Edit the config
nano mailcow.conf

# Find and change these values:
SKIP_CLAMD=y
SKIP_SOLR=y
```
Then start the containers: 
```bash
sudo docker compose up -d
```

---

## 💾 Backup and Restoration

### Automated Backup
Copy the `scripts/backup_mailcow.sh` to `/opt/mailcow-dockerized/scripts/`.

**To automate (Cronjob):**
```bash
# Edit crontab
sudo crontab -e

# Add this line (Runs daily at 3 AM)
0 3 * * * /bin/bash /opt/mailcow-dockerized/scripts/backup_mailcow.sh >> /var/log/mailcow-backup.log 2>&1
```

### Restoration
1. Ensure Mailcow is stopped: `docker compose down`.
2. Run the restoration:
```bash
export MAILCOW_BACKUP_LOCATION="/opt/mailcow-backups/latest"
./helper-scripts/backup_and_restore.sh restore
```

---

## 🔄 Upgrading
Mailcow makes updates easy:
```bash
cd /opt/mailcow-dockerized
sudo ./update.sh
```
*Always take a backup before updating!*

---

## 🛡️ Security & Maintenance
Mailcow is secure by default, but here are extra steps:
- **Fail2Ban:** Integrated by default. It blocks IPs with too many failed logins.
- **Two-Factor Authentication (2FA):** Enable this in the Mailcow UI (Settings -> Password & 2FA).
- **Updates:** Run `./update.sh` once a month to keep things patched.
- **Monitoring:** Mailcow's dashboard shows CPU, RAM, and Disk usage in real-time.

---

## 🛠️ Maintenance & Stability
- **ClamAV/Solr:** If you have low RAM, you can disable these in `mailcow.conf` to improve stability.
- **Logs:** Use `docker-compose logs -f --tail=100` to monitor.
- **Health Checks:** Mailcow includes built-in health checks for all services.

---

## 🌐 DNS Records Required

Replace `[Your Lightsail IP]` with your actual static IP.

| Type | Host | Value | Cloudflare Proxy |
|------|------|-------|------------------|
| A | `mail` | `[Your Lightsail IP]` | **DNS ONLY (Grey Cloud)** |
| MX | `@` | `mail.bytenex.io` (Priority 10) | **DNS ONLY** |
| TXT | `@` | `v=spf1 mx a:mail.bytenex.io -all` | **DNS ONLY** |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine;` | **DNS ONLY** |
| TXT | `mail._domainkey` | `[Get from Mailcow UI]` | **DNS ONLY** |

### For Additional Domains (arogyamayurveda.com, etc.):
| Type | Host | Value |
|------|------|-------|
| MX | `@` | `mail.bytenex.io` |
| TXT | `@` | `v=spf1 mx a:mail.bytenex.io -all` |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine;` |
| TXT | `dkim._domainkey` | `[Get from Mailcow UI]` |
