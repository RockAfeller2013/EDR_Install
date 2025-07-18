#!/bin/bash
# curl -S -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/install_caldera.sh | bash

# Full CALDERA Installer for Kali Linux
# Includes: CALDERA + Go + Sandcat + HTTPS + All Official Plugins + Headless Mode
# chmod +x install_caldera.sh
# sudo ./install_caldera.sh
# Access CALDERA: https://<your-ip>:8888
# Default red team is auto-logged in with --headless mode enabled
# Agents:
#   agents/sandcat/sandcat.exe (Windows)
#   agents/sandcat/sandcat (Linux)

set -e

# --- CONFIG ---
CALDERA_DIR="/opt/caldera"
GO_VERSION="1.20.12"
PLUGINS=("manx" "stockpile" "response" "compass" "access" "atomic" "builder" "debrief" "fieldmanual" "exfil")

# --- SYSTEM UPDATE ---
echo "[*] Updating system..."
sudo apt update && sudo apt upgrade -y

# --- INSTALL DEPENDENCIES ---
echo "[*] Installing required packages..."
sudo apt install -y git curl wget tar openssl build-essential \
  libxml2-dev libxslt1-dev zlib1g-dev libffi-dev gcc \
  python3.8 python3.8-venv python3.8-dev

# --- INSTALL Node.js v16.x ---
echo "[*] Installing Node.js v16.x..."
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify node and npm versions
node -v
npm -v

# --- INSTALL GO ---
echo "[*] Installing Go $GO_VERSION..."
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go${GO_VERSION}.linux-amd64.tar.gz

export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc

# --- CLONE CALDERA ---
echo "[*] Cloning CALDERA v5.0.0..."
sudo git clone https://github.com/mitre/caldera.git --branch 5.0.0 "$CALDERA_DIR"
sudo chown -R $USER:$USER "$CALDERA_DIR"
cd "$CALDERA_DIR"

# --- PYTHON VENV SETUP ---
echo "[*] Creating Python 3.8 virtual environment..."
python3.8 -m venv venv
source venv/bin/activate

echo "[*] Installing Python packages..."
pip install --upgrade pip setuptools wheel
sed -i 's/lxml==4.9.3/lxml>=4.9.3/' requirements.txt
pip install -r requirements.txt

# --- GENERATE SELF-SIGNED CERTS ---
echo "[*] Generating TLS certs..."
mkdir -p "$CALDERA_DIR"/certs
openssl req -x509 -newkey rsa:4096 -nodes -keyout "$CALDERA_DIR/certs/key.pem" -out "$CALDERA_DIR/certs/cert.pem" -days 365 -subj "/CN=caldera.local"

# --- BUILD SANDCAT AGENT ---
echo "[*] Building Sandcat agent..."
cd "$CALDERA_DIR/agents/sandcat"
go mod tidy
GOOS=windows GOARCH=amd64 go build -o sandcat.exe ./gocat.go
GOOS=linux GOARCH=amd64 go build -o sandcat ./gocat.go

# --- INSTALL OFFICIAL PLUGINS ---
cd "$CALDERA_DIR/plugins"
for plugin in "${PLUGINS[@]}"; do
  echo "[*] Cloning plugin: $plugin"
  git clone "https://github.com/mitre/${plugin}.git"
done

# --- AUTO-LOGIN SERVER STARTUP (optional) ---
cat <<EOF > "$CALDERA_DIR/start_caldera.sh"
#!/bin/bash
cd "$CALDERA_DIR"
source venv/bin/activate
python3.8 server.py --insecure --plugins all
EOF
chmod +x "$CALDERA_DIR/start_caldera.sh"

echo
echo "[✓] CALDERA installed with Sandcat, HTTPS, official plugins, and Node.js v16+."
echo
echo "👉 To run securely with TLS:"
echo "cd $CALDERA_DIR && source venv/bin/activate && python3.8 server.py --certfile certs/cert.pem --keyfile certs/key.pem --plugins all"
echo
echo "👉 Or run headless (insecure, no browser prompts):"
echo "$CALDERA_DIR/start_caldera.sh"
