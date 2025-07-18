#!/bin/bash
# curl -S -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/nstall_caldera_docker.sh | bash

set -e

# Check Docker
if ! command -v docker &>/dev/null; then
  echo "[*] Installing Docker..."
  sudo apt update
  sudo apt install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
  echo
  echo "# IMPORTANT:"
  echo "# After first run, logout/login or run: newgrp docker"
  exit 1
fi

echo "[*] Preparing Caldera Docker build..."

mkdir -p ~/caldera-docker
cd ~/caldera-docker

# Clone Caldera repo locally
if [ ! -d caldera ]; then
  git clone --branch 5.0.0 https://github.com/mitre/caldera.git
fi

# Write Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.8-slim

# Install deps
RUN apt-get update && apt-get install -y \
    git curl wget build-essential libxml2-dev libxslt1-dev zlib1g-dev libffi-dev gcc \
    golang-go nodejs npm openssl \
 && rm -rf /var/lib/apt/lists/*

# Set workdir
WORKDIR /opt/caldera

# Copy caldera source
COPY caldera /opt/caldera

# Set up virtualenv + install deps
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    sed -i 's/lxml==4.9.3/lxml>=4.9.3/' requirements.txt && \
    pip install -r requirements.txt

# Build sandcat agents
RUN . venv/bin/activate && \
    cd agents/sandcat && \
    go mod tidy && \
    GOOS=windows GOARCH=amd64 go build -o sandcat.exe ./gocat.go && \
    GOOS=linux GOARCH=amd64 go build -o sandcat ./gocat.go

# Install all plugins
RUN mkdir -p plugins && cd plugins && \
    git clone https://github.com/mitre/manx.git && \
    git clone https://github.com/mitre/stockpile.git && \
    git clone https://github.com/mitre/response.git && \
    git clone https://github.com/mitre/compass.git && \
    git clone https://github.com/mitre/access.git && \
    git clone https://github.com/mitre/atomic.git && \
    git clone https://github.com/mitre/builder.git && \
    git clone https://github.com/mitre/debrief.git && \
    git clone https://github.com/mitre/fieldmanual.git && \
    git clone https://github.com/mitre/exfil.git

# Generate TLS certs
RUN mkdir certs && \
    openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout certs/key.pem -out certs/cert.pem -days 365 \
    -subj "/CN=caldera.local"

EXPOSE 8888

CMD ["bash", "-c", "source venv/bin/activate && python3 server.py --certfile certs/cert.pem --keyfile certs/key.pem --plugins all"]
EOF

# Build Docker image
docker build -t caldera:5.0.0 .

# Run container
docker run -d -p 8888:8888 --name caldera caldera:5.0.0

echo
echo "[✓] Caldera is running in Docker on https://localhost:8888"
echo "    Username: red | Password: admin"
echo
echo "# If Docker was just installed, logout/login or run: newgrp docker"

