#!/bin/bash

# Function to print messages
print_msg() {
    echo -e "\n************ $1 ************"
}

# Function to check and install software packages
install_package() {
    local package=$1
    if ! dpkg -l | grep -q "^ii\s\+$package"; then
        apt-get install -y $package
        print_msg "$package installed"
    else
        print_msg "$package already installed"
    fi
}

# Check and configure network interface
print_msg "Configuring network interface"
NETPLAN_CONFIG="/etc/netplan/01-netcfg.yaml"
if ! grep -q "192.168.16.21/24" $NETPLAN_CONFIG; then
    cat <<EOL >> $NETPLAN_CONFIG
network:
  version: 2
  ethernets:
    eth1:
      addresses: [192.168.16.21/24]
EOL
    netplan apply
    print_msg "Network interface configured"
else
    print_msg "Network interface already configured"
fi

# Update /etc/hosts file
print_msg "Updating /etc/hosts"
HOSTS_FILE="/etc/hosts"
if ! grep -q "192.168.16.21 server1" $HOSTS_FILE; then
    sed -i '/server1/d' $HOSTS_FILE
    echo "192.168.16.21 server1" >> $HOSTS_FILE
    print_msg "/etc/hosts updated"
else
    print_msg "/etc/hosts already updated"
fi

# Install and start apache2 and squid
print_msg "Installing apache2 and squid"
install_package apache2
install_package squid

systemctl enable apache2
systemctl start apache2
print_msg "apache2 started"

systemctl enable squid
systemctl start squid
print_msg "squid started"

# Configure UFW firewall
print_msg "Configuring UFW firewall"
sudo apt install ufw -y
ufw allow in on eth0 to any port 22
ufw allow in on eth1 to any port 22
ufw allow in on eth0 to any port 80
ufw allow in on eth0 to any port 3128
ufw allow in on eth1 to any port 80
ufw allow in on eth1 to any port 3128
ufw --force enable
print_msg "UFW firewall configured"

# Create user accounts
print_msg "Creating user accounts"
USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${USERS[@]}"; do
    if ! id -u $user &>/dev/null; then
        useradd -m -s /bin/bash $user
        print_msg "User $user created"
    else
        print_msg "User $user already exists"
    fi
done

# Configure ssh keys and sudo access for dennis
print_msg "Configuring ssh keys and sudo access"
SSH_KEYS_DIR="/home/dennis/.ssh"
if [ ! -d $SSH_KEYS_DIR ]; then
    mkdir -p $SSH_KEYS_DIR
    chown dennis:dennis $SSH_KEYS_DIR
    chmod 700 $SSH_KEYS_DIR
fi

cat <<EOL > $SSH_KEYS_DIR/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm
EOL
chown dennis:dennis $SSH_KEYS_DIR/authorized_keys
chmod 600 $SSH_KEYS_DIR/authorized_keys
print_msg "SSH key added for dennis"

usermod -aG sudo dennis
print_msg "Sudo access granted to dennis"

# Ensure idempotency
print_msg "Script execution complete. This script created by ZAMIR AZIMOV."

