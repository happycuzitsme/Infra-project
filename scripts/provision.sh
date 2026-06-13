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
	sudo cp ~/infra-project/systemd/infra-demo.service /etc/systemd/system/
	sudo systemctl daemon reload
else
	log_warn "Service file already exists, updating..."
	sudo cp ~/infra-project/systemd/infra-demo.service /etc/systemd/system/
	sudo systemctl daemon-reload
fi

#Enable and start service
sudo systemctl enable infra-demo
sudo systemctl start infra-demo
#==========================================
#Verification
#==========================================
log_info "===Verification==="
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

log_info "===Stage 3 Base Provisioning Complete ==="

