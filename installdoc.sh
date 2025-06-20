#!/bin/bash
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/installdoc.sh)"


# Exit on error
set -e

echo "Installing Docker on CentOS..."

# Remove older versions
sudo yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# Install required packages
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# Add Docker repo
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Test Docker
sudo docker run hello-world

echo "Docker installed successfully on CentOS."
