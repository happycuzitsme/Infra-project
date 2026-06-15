# Test Plan

## Overview

This document outlines all test cases for the infrastructure provisioning project. Each test includes steps, expected results, and actual results.

---

## Test Environment

| Item | Specification |
|------|---------------|
| OS | Ubuntu Server 22.04 LTS |
| RAM | 2 GB |
| Disk | 10 GB (dynamically allocated) |
| Virtualization | VirtualBox 7.x |
| Network | NAT (with port forwarding) |

---

## Test Cases

### TC-01: OS Detection

| | |
|---|---|
| **Purpose** | Verify script detects Ubuntu 22.04/24.04 |
| **Steps** | Run `sudo ./scripts/provision.sh` |
| **Expected** | "Detected: Ubuntu 22.04.x" |
| **Status** | ✅ PASS |

---

### TC-02: Package Installation

| | |
|---|---|
| **Purpose** | Verify required packages install |
| **Steps** | Run provision script, check packages |
| **Expected** | nginx, ufw, curl, python3, git, vim, htop installed |
| **Verification** | `dpkg -l \| grep nginx` |
| **Status** | ✅ PASS |

---

### TC-03: User Creation

| | |
|---|---|
| **Purpose** | Verify non-root sudo user created |
| **Steps** | Run provision script |
| **Expected** | User 'deployer' exists with sudo access |
| **Verification** | `id deployer` and `groups deployer` |
| **Status** | ✅ PASS |

---

### TC-04: Directory Creation

| | |
|---|---|
| **Purpose** | Verify application directories created |
| **Steps** | Run provision script |
| **Expected** | `/opt/infra-demo` and `/var/log/infra-demo` exist |
| **Verification** | `ls -la /opt/infra-demo` |
| **Status** | ✅ PASS |

---

### TC-05: Service Deployment

| | |
|---|---|
| **Purpose** | Verify app.py deployed to /opt/infra-demo |
| **Steps** | Run provision script |
| **Expected** | `/opt/infra-demo/app.py` exists and executable |
| **Verification** | `file /opt/infra-demo/app.py` |
| **Status** | ✅ PASS |

---

### TC-06: Environment File

| | |
|---|---|
| **Purpose** | Verify config.env deployed with correct permissions |
| **Steps** | Run provision script |
| **Expected** | File exists, permissions 600, owned by deployer |
| **Verification** | `stat -c "%a %U" /opt/infra-demo/config.env` |
| **Status** | ✅ PASS |

---

### TC-07: systemd Service

| | |
|---|---|
| **Purpose** | Verify service file installed correctly |
| **Steps** | Run provision script |
| **Expected** | `/etc/systemd/system/infra-demo.service` exists |
| **Verification** | `systemctl cat infra-demo` |
| **Status** | ✅ PASS |

---

### TC-08: Service Running

| | |
|---|---|
| **Purpose** | Verify service starts and runs |
| **Steps** | After provision, check service status |
| **Expected** | Active (running) |
| **Verification** | `systemctl is-active infra-demo` |
| **Status** | ✅ PASS |

---

### TC-09: Service Enabled on Boot

| | |
|---|---|
| **Purpose** | Verify service starts automatically after reboot |
| **Steps** | Check enabled status, then reboot and check |
| **Expected** | Enabled, running after reboot |
| **Verification** | `systemctl is-enabled infra-demo` |
| **Status** | ✅ PASS |

---

### TC-10: Health Endpoint

| | |
|---|---|
| **Purpose** | Verify /health returns OK |
| **Steps** | `curl http://localhost:8080/health` |
| **Expected** | Output: "OK" |
| **Status** | ✅ PASS |

---

### TC-11: Firewall Configuration

| | |
|---|---|
| **Purpose** | Verify UFW active with correct rules |
| **Steps** | Check firewall status and rules |
| **Expected** | Active, ports 22 and 8080 allowed |
| **Verification** | `ufw status verbose` |
| **Status** | ✅ PASS |

---

### TC-12: SSH Hardening

| | |
|---|---|
| **Purpose** | Verify SSH security settings |
| **Steps** | Check sshd_config |
| **Expected** | `PermitRootLogin no`, `PasswordAuthentication no` |
| **Verification** | `grep` commands |
| **Status** | ✅ PASS |

---

### TC-13: File Permissions

| | |
|---|---|
| **Purpose** | Verify config.env has correct permissions |
| **Steps** | Check file permissions |
| **Expected** | 600 (rw-------) |
| **Verification** | `stat -c %a /opt/infra-demo/config.env` |
| **Status** | ✅ PASS |

---

### TC-14: Log Accessibility

| | |
|---|---|
| **Purpose** | Verify logs readable via journalctl |
| **Steps** | Read service logs |
| **Expected** | Logs visible, no permission errors |
| **Verification** | `journalctl -u infra-demo -n 5` |
| **Status** | ✅ PASS |

---

### TC-15: Maintenance Timer

| | |
|---|---|
| **Purpose** | Verify timer installed and active |
| **Steps** | Check timer status |
| **Expected** | Active, enabled |
| **Verification** | `systemctl status infra-maintenance.timer` |
| **Status** | ✅ PASS |

---

### TC-16: Idempotency

| | |
|---|---|
| **Purpose** | Verify running provision.sh twice doesn't break system |
| **Steps** | Run provision.sh, then run again |
| **Expected** | Warnings (already exists), NO errors |
| **Status** | ✅ PASS |

---

### TC-17: Reboot Survival

| | |
|---|---|
| **Purpose** | Verify service survives reboot |
| **Steps** | Reboot VM, run validation |
| **Expected** | All validation checks pass after reboot |
| **Status** | ✅ PASS |

---

### TC-18: Validation Script

| | |
|---|---|
| **Purpose** | Verify validate.sh checks all components |
| **Steps** | Run `./scripts/validate.sh` |
| **Expected** | All 18+ checks PASS |
| **Status** | ✅ PASS |

---

## Test Results Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-01 | OS Detection | ✅ |
| TC-02 | Package Installation | ✅ |
| TC-03 | User Creation | ✅ |
| TC-04 | Directory Creation | ✅ |
| TC-05 | Service Deployment | ✅ |
| TC-06 | Environment File | ✅ |
| TC-07 | systemd Service | ✅ |
| TC-08 | Service Running | ✅ |
| TC-09 | Service Enabled on Boot | ✅ |
| TC-10 | Health Endpoint | ✅ |
| TC-11 | Firewall Configuration | ✅ |
| TC-12 | SSH Hardening | ✅ |
| TC-13 | File Permissions | ✅ |
| TC-14 | Log Accessibility | ✅ |
| TC-15 | Maintenance Timer | ✅ |
| TC-16 | Idempotency | ✅ |
| TC-17 | Reboot Survival | ✅ |
| TC-18 | Validation Script | ✅ |

**Total Passed:** 18/18 ✅

---

## Idempotency Test Output

### First Run