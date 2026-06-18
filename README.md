
# 🖥️ Infrastructure Provisioning Project

> A production-ready Linux server baseline with automated provisioning, systemd service, security hardening, and reboot validation.

---

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Components](#components)
- [Security Hardening](#security-hardening)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Repository Structure](#repository-structure)
- [AI Assistance](#ai-assistance)

---

## 🚀 Quick Start

### Prerequisites
- Ubuntu Server 22.04 or 24.04 LTS
- 2GB RAM, 10GB disk space
- Internet connection

### One-Command Setup

```bash
git clone https://github.com/YOUR_USERNAME/infra-project.git
cd infra-project
sudo ./scripts/provision.sh
```

### Validate Installation

```bash
./scripts/validate.sh
```

### Test Health Endpoint

```bash
curl http://localhost:8080/health
# Output: OK
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Ubuntu VM (22.04/24.04)              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   systemd    │  │    UFW       │  │   deployer   │  │
│  │  infra-demo  │  │  Firewall    │  │  (sudo user) │  │
│  │   service    │  │ 22/8080 open │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                                               │
│         ▼                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │    Python    │  │  config.env  │  │ maintenance  │  │
│  │   Health     │◄─┤  (PORT=8080) │  │    timer     │  │
│  │   Service    │  │              │  │  (daily)     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
            http://localhost:8080/health → "OK"
```

---

## 📦 Components

| Component | Path | Purpose |
|-----------|------|---------|
| **Provisioning Script** | `scripts/provision.sh` | Automates full server setup |
| **Validation Script** | `scripts/validate.sh` | Checks all systems (18+ tests) |
| **Demo Service** | `/opt/infra-demo/app.py` | Python HTTP health endpoint |
| **systemd Unit** | `/etc/systemd/system/infra-demo.service` | Manages service lifecycle |
| **Environment File** | `/opt/infra-demo/config.env` | Runtime configuration |
| **Maintenance Timer** | `/etc/systemd/system/infra-maintenance.timer` | Daily log cleanup |

### API Endpoints

| Endpoint | Method | Response | Status |
|----------|--------|----------|--------|
| `/health` | GET | `OK` | 200 |
| Any other | GET | `Not Found` | 404 |

---

## 🔒 Security Hardening

### Applied Measures

| Area | Setting | Justification |
|------|---------|---------------|
| **Firewall** | UFW active, default deny incoming | Blocks unauthorized access |
| **SSH** | `PermitRootLogin no` | Prevents direct root access |
| **SSH** | `PasswordAuthentication no` | Requires key-based authentication |
| **User** | Non-root `deployer` with sudo | Least privilege principle |
| **Permissions** | `config.env` = 600 | Sensitive data protection |
| **systemd** | `NoNewPrivileges=yes` | Prevents privilege escalation |
| **systemd** | `PrivateTmp=yes` | Isolates temporary files |
| **Logging** | 7-day retention via timer | Automatic log rotation |


### Verification Commands

```bash
sudo ufw status verbose
sudo grep -E "PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config
stat -c "%a %U:%G" /opt/infra-demo/config.env
sudo systemctl status infra-maintenance.timer
```

---

## 🧪 Testing

### Before Reboot

```bash
sudo ./scripts/provision.sh
./scripts/validate.sh
```

**Expected:** All 18+ checks show `[PASS]`

### After Reboot (Critical Test)

```bash
sudo reboot
# Wait 30 seconds, log back in
cd ~/infra-project
./scripts/validate.sh
```

**Expected:** Same `[PASS]` results - service survived reboot!

### Idempotency Test

```bash
sudo ./scripts/provision.sh   # First run
sudo ./scripts/provision.sh   # Second run - should show WARNINGS, not errors
```

---

## 🔧 Troubleshooting

### Service Won't Start

```bash
sudo journalctl -u infra-demo -n 50 --no-pager
sudo systemctl restart infra-demo
```

### Port 8080 Already in Use

```bash
sudo ss -tulpn | grep 8080
sudo systemctl stop <conflicting-service>
```

### Firewall Blocking Access

```bash
sudo ufw status verbose
sudo ufw allow 8080/tcp
```

### Permission Denied

```bash
sudo chown -R deployer:deployer /opt/infra-demo
sudo chmod 600 /opt/infra-demo/config.env
sudo chmod 755 /opt/infra-demo/app.py
```

### Validation Shows False Errors

```bash
# Clear old logs
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s
sudo systemctl restart infra-demo
```

---

## 📁 Repository Structure

```
infra-project/
├── scripts/
│   ├── provision.sh           # Main setup script (idempotent)
│   └── validate.sh            # 18+ validation checks
├── config/
│   └── infra-demo.env         # PORT=8080, LOG_DIR
├── systemd/
│   ├── infra-demo.service     # systemd unit file
│   ├── infra-maintenance.service
│   └── infra-maintenance.timer  # Daily log cleanup
├── docs/
│   └── hardening-checklist.md   # Security documentation
├── opt/
│   └── infra-demo/
│       └── app.py             # Python health service
├── evidence/                   # 21 screenshots (Stage 1-7)
│   ├── 1-vm-running.png
│   ├── ...
│   └── 21-hardening-checklist.png
└── README.md                   # This file
```

---

## 🤖 AI Assistance Notes

| Area | AI Usage | Manual Verification |
|------|----------|---------------------|
| systemd unit templates | Initial structure | ✅ Tested on Ubuntu 22.04 |
| Bash script error handling | Boilerplate patterns | ✅ Idempotency verified |
| Documentation formatting | Structure suggestions | ✅ All commands executed |
| Hardening checklist | Common practices | ✅ Tailored to assignment |

**All commands and configurations were manually tested in a local Ubuntu 22.04 VM.**

---

## 📝 Validation Checklist

- [x] Service running and enabled
- [x] Health endpoint returns `OK`
- [x] Firewall active (ports 22, 8080)
- [x] `deployer` user exists with sudo
- [x] `config.env` permissions = 600
- [x] Logs accessible via journalctl
- [x] Maintenance timer active
- [x] SSH root login disabled
- [x] Reboot survival confirmed

---

## 📹 Demo Video

[Click here for demo video](https://YOUR_VIDEO_LINK.com)

*Video shows: provisioning, validation before/after reboot, health endpoint test*

---

## 👨‍💻 Author

[Debojyoti Goswami]
[GitHub Profile](https://github.com/happcuzitsme)

---


## ⭐ Final Commands

```bash
# Full setup
git clone https://github.com/YOUR_USERNAME/infra-project.git
cd infra-project
sudo ./scripts/provision.sh

# Validation
./scripts/validate.sh

# Test service
curl http://localhost:8080/health

# Reboot test
sudo reboot
# After reboot:
./scripts/validate.sh
```

**All checks should pass before and after reboot!**
```

---

## Save and Push

```bash
# Save file (Ctrl+O, Enter, Ctrl+X)

# Commit and push
cd ~/infra-project
git add README.md
git commit -m "Add professional README"
git push origin main
```

---

