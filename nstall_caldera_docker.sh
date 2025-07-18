#!/bin/bash
# curl -S -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/nstall_caldera_docker.sh | bash

set -e

rm -rf ~/caldera-docker


echo "[*] Updating system..."
sudo apt update && sudo apt install -y curl git sudo

echo "[*] Installing Docker (if needed)..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER
  echo "# Important: Docker was just installed. Please run 'newgrp docker' or logout/login before continuing."
fi

echo "[*] Installing Docker Compose plugin..."
sudo apt install -y docker-compose-plugin

echo "[*] Cloning Caldera v5.0.0 (with submodules)..."
mkdir -p ~/caldera-docker && cd ~/caldera-docker
git clone --recurse-submodules --branch 5.0.0 https://github.com/mitre/caldera.git

echo "[*] Creating Dockerfile..."
cat > Dockerfile << 'EOF'
FROM python:3.8-slim

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git curl wget build-essential libxml2-dev libxslt1-dev zlib1g-dev libffi-dev \
    gcc golang-go nodejs npm openssl

WORKDIR /opt/caldera

# Copy full repo with agents
COPY caldera /opt/caldera

# Create Python venv and install requirements
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    sed -i 's/lxml==4.9.3/lxml>=4.9.3/' requirements.txt && \
    pip install -r requirements.txt

# Build Sandcat agent for Windows & Linux
RUN . venv/bin/activate && \
    cd agents/sandcat && \
    go mod tidy && \
    GOOS=windows GOARCH=amd64 go build -o sandcat.exe ./gocat.go && \
    GOOS=linux GOARCH=amd64 go build -o sandcat ./gocat.go

# Enable all plugins
RUN for dir in plugins/*; do \
      if [ -f "$dir/requirements.txt" ]; then \
        . venv/bin/activate && pip install -r "$dir/requirements.txt"; \
      fi; \
    done

CMD . venv/bin/activate && python3 server.py --headless
EOF

echo "[*] Building Docker image: caldera:5.0.0"
docker build -t caldera:5.0.0 .

echo "[*] Done. Run with:"
echo "docker run -it --rm -p 8888:8888 caldera:5.0.0"
echo "# If Docker was just installed, run 'newgrp docker' first"



