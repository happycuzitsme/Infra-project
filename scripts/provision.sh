#!/bin/bash
# Infrastructure Provisioning Script
#Stage 2: Init skeleton

set -e
set -u


#colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
nc='\033[0m'

log_info(){
echo -e "${green}[INFO]${nc} $1"
}
log_warn(){
echo -e "${yellow}[WARN]${nc} $1"
}
log_error(){
echo -e "${red}[ERROR]${nc} $1"
}
#========================================
#OS Detection
#========================================
log_info "Detecting operating system..."
if [ -f /etc/os-release ]; then
	. /etc/os-release
	OS=$NAME
	VER=$VERSION_ID
	log_info "Detected: $OS $VER"
else
	log_error "Cannot detect OS. Exiting..."
	exit 1
fi
#only support Ubuntu 22.04/24.04
if [[ ! "$OS" =~ "Ubuntu" ]] || [[ !  "$VER" =~ ^(22.04|24.04)$ ]]; then
	log_error "This script requires Ubuntu 22.04 or 24.04"
	log_error "Current: $OS $VER"
	exit 1
fi
#=========================================
# Package Installatin (idempotent)
#=========================================
log_info "Updating package index..."
sudo apt update -y

log_info "Installing required packages..."
REQUIRED_PACKAGES="nginx ufw curl python3 git vim htop"

for pkg in $REQUIRED_PACKAGES; do
	if dpkg -l | grep -q "^ii $pkg "; then
		log_warn "$pkg already installed, skipping"
	else
		log_info "Installing $pkg..."
		sudo apt install -y $pkg
	fi
done

#========================================
# FIREWALL CONFIGURATION (Idempotent)
#========================================
log_info "Configuring firewall..."

#Check if UFW is already configured
if sudo ufw status | grep -q "Status: active"; then
	log_warn "Firewall already active, checking rules..."
else 
	log_info "Setting up firewall rules..."
	# Default policies
	sudo ufw default deny incoming
	sudo ufw default allow outgoing

	#Allow SSH and demo service
	sudo ufw allow 22/tcp comment 'SSH'
	sudo ufw allow 8080/tcp comment 'Infra Demo Service'

	#Enable firewall (non-interactive)
	echo "y" | sudo ufw enable
	log_info "Firewall enabled"
fi

# Verify rules
sudo ufw status verbose

#========================================
# SSH Hardening (Idempotent)
#========================================

log_info "Hardening SSH configuration..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup original if not already backed up
if [ ! -f ${SSHD_CONFIG}.backup ]; then
	sudo cp ${SSHD_CONFIG} ${SSHD_CONFIG}.backup
	log_info "SSH config backed up"
fi

#Apply hardening settings (only if not already set)
if ! grep -q "^PermitRootLogin no" ${SSHD_CONFIG}; then
	sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' ${SSHD_CONFIG}
	sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' ${SSHD_CONFIG}
	log_info "Disabled root login"
fi

if ! grep -q "^PasswordAuthentication no" ${SSHD_CONFIG}; then
	sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' ${SSHD_CONFIG}
	log_info "Disabled password authentication"
fi

#Restart SSh only if config changed 
if sudo systemctl is-active ssh &>/dev/null; then
	sudo systemctl restart ssh
	log_info "SSH restarted"
fi
#========================================
#Create non-root sudo user (idempotent)
#========================================
nonroot_user="deployer"
if id "$nonroot_user" &>/dev/null; then
	log_warn "User $nonroot_user already exists, skipping creation"
else
	log_info "Creating user: $nonroot_user"
	sudo useradd -m -s /bin/bash -G sudo "$nonroot_user"
	echo "$nonroot_user:deployer123" | sudo chpasswd
	log_info "Password set to: deployer123 (change this in production)"
fi

#verify sudo access
if groups "$nonroot_user" | grep -q sudo; then
	log_info "$nonroot_user has sudo access"
else 
	log_error "$nonroot_user does not have sudo access"
	exit 1
fi
#==========================================
#Directory Setup
#==========================================
log_info "Creating application directories..."
sudo mkdir -p /opt/infra-demo
sudo mkdir -p /var/log/infra-demo
sudo chown -R "$nonroot_user":"$nonroot_user" /opt/infra-demo
sudo chown -R "$nonroot_user":"$nonroot_user" /var/log/infra-demo

log_info  "Directories created and permissions set"

#==========================================
#Demo Service Deployment
#==========================================
log_info "Deploying demo service..."

#Copy application files(if not already there)
if [ ! -f /opt/infra-demo/app.py ]; then
	log_info "Copying application files..."
	sudo cp ~/infra-project/opt/infra-demo/app.py /opt/infra-demo/ 2>/dev/null || echo "app.py will be created manually"
	sudo chmod +x /opt/infra-demo/app/py
else 
	log_warn "app.py already exists, skipping"
fi

#Copy environment file
if [ ! -f /opt/infra-demo/config.env ]; then
	log_info "Copying environment file..."
	sudo cp ~/infra-project/config/infra-demo.env /opt/infra-demo/config.env
	sudo chmod 600 /opt/infra-demo/config.env
else
	log_warn "config.env already exists, skipping"
fi

#Install systemd service
if [ ! -f /etc/systemd/system/infra-demo.service ]; then
	log_info "Installing systemd service..."
	sudo cp systemd/infra-demo.service /etc/systemd/system/
	sudo systemctl daemon-reload
else
	log_warn "Service file already exists, updating..."
	sudo cp systemd/infra-demo.service /etc/systemd/system/
	sudo systemctl daemon-reload
fi

#Enable and start service
sudo systemctl enable infra-demo
sudo systemctl start infra-demo

#==========================================
#Maintenance Timer (idempotent)
#==========================================
log_info "Setting up maintenance timer..."

#Copy service and timer files
sudo cp systemd/infra-maintenance.service /etc/systemd/system/
sudo cp systemd/infra-maintenance.timer /etc/systemd/system/

#Reload system
sudo systemctl daemon-reload

#Enable and start timer

sudo systemctl enable infra-maintenance.timer
sudo systemctl start infra-maintenance.timer

log_info "Maintenance timer configured"

#==========================================
#Verification
#==========================================

log_info "===Final Verification==="

#check packages

for pkg in nginx ufw curl python3 git; do
	if dpkg -s "$pkg" &>/dev/null; then
		log_info "$pkg installed"
	else
		log_error "$pkg missing"
		exit 1
	fi
done

#check user

if id "$nonroot_user" &>/dev/null; then
	log_info "User $nonroot_user exists"
else
	log_error "user $nonroot_user missing"
	exit 1
fi

#check directories

for dir in  /opt/infra-demo /var/log/infra-demo; do
	if [ -d "$dir" ]; then
		log_info "Directory $dir exists"
	else
		log_error "Directory $dir missing"
		exit 1
	fi
done

#Check app.py

if systemctl is-active infra-demo &>/dev/null; then
	log_info "Service running"
else
	log_error "Service not running"
	exit 1
fi

# Check firewall

if sudo ufw status | grep -q "Status: active"; then
	log_info "Firewall is active"
else
	log_error "Firewall not active"
	exit 1
fi

# Check firewall rules

if sudo ufw status | grep -q "22/tcp.*ALLOW"; then
	log_info "SSH port 22 allowed"
else
	log_error "SSH port 22 not allowed"
fi

if sudo ufw status | grep -q "8080/tcp.*ALLOW"; then
	log_info "Demo port 8080 allowed"
else
	log_error "Demo port 8080 not allowed"
fi

#Check timer

if systemctl is-active infra-maintenance.timer &>/dev/null; then
	log_info  "Maintenance timer active"
else
	log_warn "Maintenance timer not active (optional)"
fi

log_info "===Stage 5 Provisioning Complete ==="

