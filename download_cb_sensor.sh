#!/bin/bash
# Usage:
#   chmod +x download_cb_sensor.sh
#   ./download_cb_sensor.sh
#
# Description:
#   This script authenticates to a Carbon Black EDR server,
#   retrieves an API token, and downloads the Linux sensor installer.
#   Requires `jq` to parse JSON.
#
# Command-line usage:
#   Interactive mode (default):
#       ./download_cb_sensor.sh
#
#   Non-interactive mode (pass arguments directly):
#       ./download_cb_sensor.sh <CB_SERVER> <USERNAME> <PASSWORD_FILE|PASSWORD> [OUTPUT_FILE]
#
# Examples:
#   ./download_cb_sensor.sh cb.example.local admin /path/to/password_file
#   ./download_cb_sensor.sh 192.168.1.30 cbadmin 'SecretPass!' cb_sensor.tar.gz
#   ./download_cb_sensor.sh cb.example.local admin MyPass123

# sudo dnf install -y jq

# curl -sSL https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/download_cb_sensor.sh | bash -s -- 192.168.1.30 admin Password1!
# https://developer.carbonblack.com/reference/enterprise-response/latest/rest-api/#download-sensor-installer

# Usage: ./download_cb_sensor.sh <CB_SERVER> <USERNAME> <PASSWORD> [OUTPUT_FILE]
# Example: ./download_cb_sensor.sh cb.example.local admin MyPassword123
# Check if minimum arguments provided

# To create an API key in Carbon Black:

# Log into the Carbon Black web console at https://192.168.1.30
# Navigate to User Management → API Keys
# Click Add API Key
# Give it a name and appropriate permissions
# Copy the generated token

# ./download_cb_sensor.sh 192.168.1.30 YOUR_API_TOKEN_HERE

#!/bin/bash
# Usage: ./download_cb_sensor.sh <CB_SERVER> <API_TOKEN> [OUTPUT_FILE]

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <CB_SERVER> <API_TOKEN> [OUTPUT_FILE]"
    echo "Example: $0 192.168.1.30 YOUR_API_TOKEN sensor.tar.gz"
    echo ""
    echo "To get an API token:"
    echo "1. Log into Carbon Black web console"
    echo "2. Go to User Management > API Keys"
    echo "3. Create a new API key"
    exit 1
fi

CB_SERVER="$1"
API_TOKEN="$2"
OUTPUT="${3:-sensor-installer-linux.tar.gz}"

echo "Downloading sensor installer..."
curl -k -f -H "X-Auth-Token: $API_TOKEN" \
     -o "$OUTPUT" \
     "https://$CB_SERVER/api/v1/group/1/installer/linux"

if [ $? -eq 0 ] && [ -s "$OUTPUT" ]; then
    echo "Download complete: $OUTPUT"
    echo "File size: $(du -h "$OUTPUT" | cut -f1)"
else
    echo "Error: Download failed or file is empty."
    exit 1
fi
