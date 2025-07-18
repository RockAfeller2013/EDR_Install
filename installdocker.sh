#!/bin/bash
# curl -S -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/installdocker.sh
#!/bin/bash
set -e

# Check if docker is installed
if ! command -v docker &> /dev/null; then
  echo "[*] Docker not found. Installing Docker..."
  sudo apt update
  sudo apt install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
  echo "[*] Adding $USER to docker group..."
  sudo usermod -aG docker $USER
  echo
  echo "# IMPORTANT:"
  echo "# After first run, if Docker wasn’t installed before, logout and login again or run:"
  echo "#    newgrp docker"
  echo
  echo "[*] Please logout/login or run 'newgrp docker' and then run this script again."
  exit 1
else
  echo "[*] Docker is installed."
fi

IMAGE_NAME="caldera:5.0.0"
CONTAINER_NAME="caldera"
WORKDIR="$HOME/caldera-docker"

echo "[*] Creating working directory at $WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "[*] Writing Dockerfile..."
cat > Dockerfile << 'EOF'
# Use official python 3.8 image as base
FROM python:3.8-slim

# Install system deps
RUN apt-get update && apt-get install -y \
    git curl wget openssl build-essential libxml2-dev libxslt1-dev zlib1g-dev libffi-dev gcc \
    golang-go nodejs npm \
 && rm -rf /var/lib/apt/lists/*

# Set working dir
WORKDIR /opt/caldera

# Clone CALDERA v5.0.0
RUN git clone --branch 5.0.0 https://github.com/mitre/caldera.git .

# Install python deps
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    sed -i 's/lxml==4.9.3/lxml>=4.9.3/' requirements.txt && \
    pip install -r requirements.txt

# Build Sandcat agent
RUN . venv/bin/activate && \
    cd agents/sandcat && \
    go mod tidy && \
    GOOS=windows GOARCH=amd64 go build -o sandcat.exe ./gocat.go && \
    GOOS=linux GOARCH=amd64 go build -o sandcat ./gocat.go

# Install official plugins
RUN mkdir plugins && cd plugins && \
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

# Generate self-signed certs
RUN mkdir certs && \
    openssl req -x509 -newkey rsa:4096 -nodes -keyout certs/key.pem -out certs/cert.pem -days 365 -subj "/CN=caldera.local"

# Expose port
EXPOSE 8888

# Default command to start CALDERA securely with all plugins
CMD ["bash", "-c", "source venv/bin/activate && python server.py --certfile certs/cert.pem --keyfile certs/key.pem --plugins all"]
EOF

echo "[*] Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

echo "[*] Running Docker container: $CONTAINER_NAME"
docker run -d -p 8888:8888 --name $CONTAINER_NAME $IMAGE_NAME

echo "[✓] CALDERA is running in Docker."
echo "Open your browser to https://localhost:8888 (default creds: red/admin)"

echo "IMPORTANT:"
echo "# After first run, if Docker wasn’t installed before, logout and login again or run:"
echo "#    newgrp docker"
