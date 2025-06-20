#!/bin/bash

# Set /etc/hosts entry
echo "192.168.193.141     cbresponse cbresponse.local" | sudo tee -a /etc/hosts

# Set the hostname
sudo hostnamectl set-hostname cbresponse
sudo systemctl restart systemd-hostnamed

# Enable NTP time sync
sudo timedatectl set-ntp true

# Install Carbon Black repo package (ensure the .rpm is in the current directory or provide full path)
#sudo rpm -ivh carbon-black-release-1.0.4-1-Carbon\ Black\ Inc._I149104.x86_64.rpm
sudo rpm -ivh chresponse.rpm

# Disable conflicting modules
sudo yum -y module disable postgresql redis python38 python39

# Install Carbon Black Enterprise
sudo yum -y install cb-enterprise

# Download cbinit.ini from GitHub
wget -O cbinit.ini https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/cbinit.ini

# Initialize Carbon Black
sudo /usr/share/cb/cbinit cbinit.ini

# Backup SSL cert
sudo /usr/share/cb/cbssl backup --out backup.bac

# Start the service
sudo service cb-enterprise start

# Check HTTPS response
curl --insecure -I https://192.168.193.141:443 | grep HTTP
curl --insecure -s --head https://192.168.193.141:443 | head -n 1

# Print access URL
echo "https://$(hostname -I | awk '{print $1}'):443"
