# Troubleshooting Guide

## Common Issues and Solutions

---

## 1. Service Issues

### Service Won't Start

**Error:** `Active: failed` or `inactive (dead)`

**Solutions:**

```bash
# Check service status
sudo systemctl status infra-demo

# View detailed logs
sudo journalctl -u infra-demo -n 50 --no-pager

# Restart the service
sudo systemctl restart infra-demo

# Check if app.py exists
ls -la /opt/infra-demo/app.py