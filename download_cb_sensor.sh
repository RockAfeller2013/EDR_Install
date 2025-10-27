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
#       ./download_cb_sensor.sh <CB_SERVER> <USERNAME> <PASSWORD> [OUTPUT_FILE]
#
# Examples:
#   ./download_cb_sensor.sh cb.example.local admin MyPass123
#   ./download_cb_sensor.sh 192.168.1.30 cbadmin 'SecretPass!' cb_sensor.tar.gz

if [ "$#" -ge 3 ]; then
  CB_SERVER="$1"
  USERNAME="$2"
  PASSWORD="$3"
  OUTPUT="${4:-sensor-installer-linux.tar.gz}"
else
  read -p "Carbon Black Server (e.g. cb.example.local): " CB_SERVER
  read -p "Username: " USERNAME
  read -s -p "Password: " PASSWORD
  echo ""
  read -p "Output file name [sensor-installer-linux.tar.gz]: " OUTPUT
  OUTPUT=${OUTPUT:-sensor-installer-linux.tar.gz}
fi

TOKEN=$(curl -s -X POST "https://$CB_SERVER/api/v1/auth" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "Error: Failed to obtain API token."
  exit 1
fi

curl -H "X-Auth-Token: $TOKEN" \
     -H "Accept: application/octet-stream" \
     -o "$OUTPUT" \
     "https://$CB_SERVER/api/v1/sensor-installer?os_type=linux"

echo "Download complete: $OUTPUT"
