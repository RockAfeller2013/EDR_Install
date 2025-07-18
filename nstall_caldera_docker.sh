#!/bin/bash
# curl -sSL https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/main/nstall_caldera_docker.sh | bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[!] This script must be run as root${NC}"
    exit 1
fi

# Function to install Docker
install_docker() {
    echo -e "${YELLOW}[*] Installing Docker...${NC}"
    # Remove old versions if they exist
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null

    # Install dependencies
    apt update
    apt install -y ca-certificates curl gnupg

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    # Start and enable Docker
    systemctl enable --now docker

    # Verify installation
    if docker --version &>/dev/null; then
        echo -e "${GREEN}[+] Docker installed successfully${NC}"
    else
        echo -e "${RED}[!] Docker installation failed${NC}"
        exit 1
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}[*] Installing Docker Compose...${NC}"
    # Try to install via package manager first
    if apt install -y docker-compose-plugin 2>/dev/null; then
        ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    else
        # Fallback to manual installation
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

    # Verify installation
    if docker-compose --version &>/dev/null; then
        echo -e "${GREEN}[+] Docker Compose installed successfully${NC}"
    else
        echo -e "${RED}[!] Docker Compose installation failed${NC}"
        exit 1
    fi
}

# Main installation function
main() {
    echo -e "${YELLOW}[*] Starting Caldera Docker installation...${NC}"

    # Update system
    echo -e "${YELLOW}[*] Updating system...${NC}"
    apt update && apt upgrade -y
    apt install -y curl git sudo

    # Install Docker if not present
    if ! command -v docker &>/dev/null; then
        install_docker
    else
        echo -e "${GREEN}[+] Docker is already installed${NC}"
    fi

    # Install Docker Compose if not present
    if ! command -v docker-compose &>/dev/null; then
        install_docker_compose
    else
        echo -e "${GREEN}[+] Docker Compose is already installed${NC}"
    fi

    # Clone Caldera
    echo -e "${YELLOW}[*] Installing Caldera...${NC}"
    if [ -d "caldera" ]; then
        echo -e "${YELLOW}[!] Caldera directory already exists. Pulling latest changes...${NC}"
        cd caldera || exit
        git pull
        git submodule update --init --recursive
    else
        git clone https://github.com/mitre/caldera.git --recursive
        cd caldera || exit
    fi

    # Start Caldera with Docker
    echo -e "${YELLOW}[*] Starting Caldera with Docker...${NC}"
    docker-compose up -d

    # Check if Caldera is running
    if docker ps | grep -q "caldera"; then
        echo -e "${GREEN}[+] Caldera is now running!${NC}"
        echo -e "${YELLOW}[*] Access Caldera at http://localhost:8888${NC}"
        echo -e "${YELLOW}[*] Default credentials: red/admin${NC}"
    else
        echo -e "${RED}[!] Caldera failed to start${NC}"
        exit 1
    fi
}

# Run main function
main
