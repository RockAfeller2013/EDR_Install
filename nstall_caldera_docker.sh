#!/bin/bash
# curl -S -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/nstall_caldera_docker.sh | bash

set -e

rm -rf ~/caldera-docker


echo "[*] Updating and installing base dependencies..."
sudo apt update && sudo apt install -y \
  git curl wget build-essential libxml2-dev libxslt1-dev zlib1g-dev libffi-dev \
  gcc golang openssl python3 python3-pip python3-venv ca-certificates lsb-release gnupg apt-transport-https

echo "[*] Installing NodeJS v16..."
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

echo "[*] Installing Docker..."
curl -fsSL https://get.docker.com | sh

echo "[*] Adding user to docker group..."
sudo usermod -aG docker $USER

echo "[*] Installing Docker Compose manually..."
DOCKER_COMPOSE_VERSION="2.24.1"
sudo curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Important: if this is the first time Docker was installed
echo "# Important:
# After first run, if Docker wasn’t installed before, logout and login again or run:
#   newgrp docker
"

echo "[*] Cloning Caldera v5..."
mkdir -p ~/caldera-docker
cd ~/caldera-docker
git clone --branch 5.0.0 https://github.com/mitre/caldera.git

echo "[*] Creating Dockerfile..."
cat << 'EOF' > Dockerfile
FROM python:3.8-slim

RUN apt-get update && apt-get install -y \
    git curl wget build-essential libxml2-dev libxslt1-dev zlib1g-dev libffi-dev \
    gcc golang-go nodejs npm openssl && \
    apt-get clean

WORKDIR /opt/caldera

COPY caldera /opt/caldera

RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    sed -i 's/lxml==4.9.3/lxml>=4.9.3/' requirements.txt && \
    pip install -r requirements.txt

RUN cd /opt/caldera/agents/sandcat && \
    go mod tidy && \
    GOOS=windows GOARCH=amd64 go build -o sandcat.exe ./gocat.go && \
    GOOS=linux GOARCH=amd64 go build -o sandcat ./gocat.go

EXPOSE 8888

CMD ["/opt/caldera/venv/bin/python", "server.py"]
EOF

echo "[*] Building Caldera Docker image..."
docker build -t caldera:5.0.0 .

echo "[*] Running Caldera on http://localhost:8888..."
docker run -d --name caldera -p 8888:8888 caldera:5.0.0

echo "[✔] Caldera v5 is now running."
echo "    Access it at: http://localhost:8888"
echo "    Default login: red / admin"
