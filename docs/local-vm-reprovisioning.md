# Local VM Reprovisioning Guide

## Purpose

This document describes how to test the provisioning script on a **fresh local VM** to verify idempotency and repeatability. No cloud VMs are used.

---

## Prerequisites

- VirtualBox (or VMware/Hyper-V) installed on local machine
- Ubuntu Server 22.04/24.04 ISO downloaded
- Minimum 2GB RAM, 10GB disk space

---

## Method 1: Snapshot & Restore (Recommended)

### Step 1: Create Clean VM

```bash
# In VirtualBox:
1. New VM → Name: "infra-clean"
2. OS: Linux → Ubuntu (64-bit)
3. Memory: 2048 MB
4. Disk: 10 GB (dynamically allocated)
5. Start VM → Install Ubuntu Server
6. Create user: "admin" / password: "admin123"
7. Install OpenSSH server