#!/bin/bash
# curl -S -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/nstall_caldera_docker.sh | bash

set -e

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

echo "[*] Cloning Caldera v5.0.0..."
mkdir -p ~/caldera-docker && cd ~/caldera-docker
git clone --depth 1 --branch 5.0.0 https://github.com/mitre/caldera.git

echo "[*] Creating Dockerfile..."
cat > Dockerfile << 'EOF'
FROM kalilinux/kali-rolling

# Install dependencies
RUN apt update && apt install -y \
    python3 python3-venv python3-dev python3-pip \
    curl git gcc make wget unzip \
    nodejs npm \
    golang

WORKDIR /opt/caldera

# Copy caldera source
COPY caldera /opt/caldera

# Set up Python virtual environment
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# Build sandcat agents
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

# Run Caldera with headless mode and default plugins
CMD . venv/bin/activate && \
    python3 server.py --headless
EOF

echo "[*] Building Docker image: caldera:5.0.0"
docker build -t caldera:5.0.0 .

echo "[*] Done! You can now run Caldera with:"
echo "docker run -it --rm -p 8888:8888 caldera:5.0.0"
echo
echo "# Important: If Docker was just installed, run this first:"
echo "newgrp docker"


