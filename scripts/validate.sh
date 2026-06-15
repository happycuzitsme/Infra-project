#!/bin/bash
#Validation script
#Checks service, health endpoint, firewall, user, logs,timer,permissions

set -e #exit on error
set -u #exit on undefined variable

#colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

log_pass(){
	echo -e "${GREEN}[PASS]${NC}$1"
	PASSED=$((PASSED+1))
}
log_fail(){
	echo -e "${RED}[FAIL]${NC}$1"
	FAILED=$((FAILED+1))
}
log_info(){
	echo -e "${YELLOW}[INFO]${NC}$1"
}

echo "========================================================"
echo "        Infrastructure Validationn Suite"
echo "========================================================"
echo ""

#===========================================================
#Check1: Service Status
#===========================================================

log_info "Checking service status..."

if systemctl is-active infra-demo &>/dev/null; then
	log_pass "infra-demo service is running)"
else
	log_fail "infra-demo service is NOT running"
fi

if systemctl is-enabled infra-demo &>/dev/null; then
	log_pass "infra-demo service is enabled (starts on boot)"
else
	log_fail "infra-demo service is NOT enabled"
fi

#===========================================================
#Check2: Health Endpoint
#===========================================================
log_info "Checking health endpoint..."

if curl -s http://localhost:8080/health | grep -q "OK"; then
	log_pass "Health endpoint returns OK"
else
	log_fail "Health endpoint failed"
fi

#===========================================================
#Check 3: Firewall Rules
#===========================================================

log_info "Checking firewall rules..."

if sudo ufw status | grep -q "Status: active"; then
	log_pass "Firewall is active"
else
	log_fail "Firewall is NOT active"
fi

if sudo ufw status | grep -q "22/tcp.*ALLOW"; then
	log_pass "SSH port 22 is allowed"
else
	log_fail "SSH port 22 is NOT allowed"
fi

if sudo ufw status | grep -q "8080/tcp.*ALLOW"; then
	log_pass "Demo port 8080 is allowed"
else
	log_fail "Demo port 8080 is NOT alowed"
fi

#===========================================================
#Check 4: User Existence
#===========================================================

log_info "Checking user configuration..."

if id deployer &>/dev/null; then
	log_pass "User 'deployer' exists"
else
	log_fail "User 'deployer' does NOT exist"
fi

if groups deployer | grep -q sudo; then
	log_pass "User 'deployer' has sudo access"
else
	log_fail "User 'deployer' does NOT have sudo access"
fi

#============================================================
#Check 5: File Permissions
#============================================================

log_info "Checking file permissions..."
if [ -f /opt/infra-demo/app.py ]; then
	log_pass "app.py exists"
	#check ownership
	if [ "$(stat -c %U /opt/infra-demo/app.py)" = "deployer" ]; then
		log_pass "app.py owned by deployer"
	else
		log_fail "app.py not owned by deployer"
	fi
else
	log_fail "app.py missing"
fi

if [ -f /opt/infra-demo/config.env ]; then
	log_pass "config.env exists"
	#check permissions (600 = rw------)
	PERM=$(stat -c %a /opt/infra-demo/config.env)
	if [ "$PERM" = "600" ]; then
		log_pass "config.env has correct permissions (600)"
	else
		log_fail "config.env has wrong permissions: $PERM(should be 600)"
	fi
else
	log_fail "config.env missing"
fi

#============================================================
#Check 6: Logs
#============================================================

log_info "Checking logs..."

if journalctl -u infra-demo --no-pager -n 5 &>/dev/null; then
	log_pass "Service logs are readable"
else
	log_fail "Cannot read service logs"
fi

#Check for recent errors in logs(exclude common harmless messages)
if journalctl -u infra-demo --no-pager -n 20 | grep -qi "traceback\|exception\|failed\|cannot\|unable\|fatal"; then
	#Filter out false positives
	ERRORS=$(journalctl -u infra-demo --no-pager -n 20 | grep -i "traceback\|exception\|failed\|cannot\|unable\|fatal" | grep -v "Started\|Stopped\|Reload" || true)
	if [ -n "$ERRORS" ]; then
		log_fail "Found errors in recent logs"
		echo "$ERRORS" | head -5
		log_info "Run: sudo journalctl -u infra-demo -n 20"
	else
		log_pass "No critical errors in logs"
	fi
else
	log_pass "No critical errors in logs"
fi
	

#============================================================
#Check 7: Maintenance Timer
#============================================================

log_info "Checking maintenance timer..."

if systemctl is-active infra-maintenance.timer &>/dev/null; then
	log_pass "Maintenance timer is active"
else
	log_fail "Maintenance timer is NOT active"
fi

#============================================================
#Check 8: SSH Hardening
#============================================================

log_info "Checking SSH hardening..."

if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
	log_pass "Root login is diabled"
else
	log_fail "Root login is NOT disabled"
fi

#=============================================================
#Check 9: Directories
#=============================================================

log_info "Checking directories..."

for dir in /opt/infra-demo /var/log/infra-demo; do 
	if [ -d "$dir" ]; then
		log_pass "Directory $dir exists"
	else
		log_fail "Directory $dir missing"
	fi
done

#=============================================================
#SUMMARY
#=============================================================

echo""
echo "=============================================================="
echo "              Validation Summary"
echo "=============================================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo "=============================================================="

if [ $FAILED -eq 0 ]; then
	echo -e "${GREEN}ALL CHECKS PASSED!${NC}"
	exit 0
else
	echo -e "${RED}SOME CHECKS FAILED!${NC}"
	exit 1
fi
