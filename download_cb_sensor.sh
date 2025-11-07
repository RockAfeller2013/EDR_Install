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

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <CB_SERVER> <USERNAME> <PASSWORD> [OUTPUT_FILE]"
    echo "Example: $0 cb.example.local admin MyPassword123 sensor.tar.gz"
    exit 1
fi

# Get arguments
CB_SERVER="$1"
USERNAME="$2"
PASSWORD="$3"
OUTPUT="${4:-sensor-installer-linux.tar.gz}"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is required but not installed. Please install jq."
    exit 1
fi

# Get API token
echo "Authenticating to Carbon Black server..."
TOKEN=$(curl -s -X POST "https://$CB_SERVER/api/v1/auth" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Failed to obtain API token. Check credentials and server address."
    exit 1
fi

echo "Downloading sensor installer..."
# Download the sensor
curl -f -H "X-Auth-Token: $TOKEN" \
     -H "Accept: application/octet-stream" \
     -o "$OUTPUT" \
     "https://$CB_SERVER/api/v1/sensor-installer?os_type=linux"

# Check if download was successful
if [ $? -eq 0 ] && [ -s "$OUTPUT" ]; then
    echo "Download complete: $OUTPUT"
    echo "File size: $(du -h "$OUTPUT" | cut -f1)"
else
    echo "Error: Download failed or file is empty."
    exit 1
fi
