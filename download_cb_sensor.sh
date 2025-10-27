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
#
# curl -sSL https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/download_cb_sensor.sh | bash -s -- cb.example.local admin MyPassword123

# Function to validate server format

validate_server() {
    local server="$1"
    # Allow domains, IP addresses, and localhost
    if [[ ! "$server" =~ ^[a-zA-Z0-9.-]+$ ]] || [[ ${#server} -gt 255 ]]; then
        echo "Error: Invalid server format. Must be a valid hostname or IP address."
        return 1
    fi
    return 0
}

# Function to validate username
validate_username() {
    local username="$1"
    if [ -z "$username" ]; then
        echo "Error: Username cannot be empty."
        return 1
    fi
    if [[ ${#username} -gt 100 ]]; then
        echo "Error: Username too long (max 100 characters)."
        return 1
    fi
    return 0
}

# Function to validate output filename
validate_output() {
    local output="$1"
    if [ -z "$output" ]; then
        echo "Error: Output filename cannot be empty."
        return 1
    fi
    # Check for directory traversal attempts
    if [[ "$output" =~ \.\./ ]] || [[ "$output" =~ ^/ ]]; then
        echo "Error: Output filename contains invalid path characters."
        return 1
    fi
    # Check for invalid characters
    if [[ ! "$output" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "Error: Output filename contains invalid characters."
        return 1
    fi
    return 0
}

# Function to read password from file or use provided password
get_password() {
    local password_input="$1"
    
    # Check if the input is a file that exists and is readable
    if [ -f "$password_input" ] && [ -r "$password_input" ]; then
        PASSWORD=$(cat "$password_input" | tr -d '\n' | tr -d '\r')
        if [ -z "$PASSWORD" ]; then
            echo "Error: Password file is empty."
            return 1
        fi
    else
        # Use the input directly as password
        PASSWORD="$password_input"
    fi
    
    # Validate password is not empty
    if [ -z "$PASSWORD" ]; then
        echo "Error: Password cannot be empty."
        return 1
    fi
    
    # Basic password length check (adjust as needed)
    if [ ${#PASSWORD} -lt 1 ]; then
        echo "Error: Password is too short."
        return 1
    fi
    
    return 0
}

# Function to cleanup sensitive data
cleanup() {
    # Securely unset sensitive variables
    unset PASSWORD 2>/dev/null || true
    unset TOKEN 2>/dev/null || true
    # Overwrite the variables in memory (basic attempt)
    PASSWORD=""
    TOKEN=""
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Main script logic
if [ "$#" -ge 3 ]; then
    # Non-interactive mode
    CB_SERVER="$1"
    USERNAME="$2"
    PASSWORD_INPUT="$3"
    OUTPUT="${4:-sensor-installer-linux.tar.gz}"
    
    # Validate inputs
    if ! validate_server "$CB_SERVER"; then
        exit 1
    fi
    
    if ! validate_username "$USERNAME"; then
        exit 1
    fi
    
    if ! validate_output "$OUTPUT"; then
        exit 1
    fi
    
    # Handle password input (file or direct)
    if ! get_password "$PASSWORD_INPUT"; then
        exit 1
    fi
    
else
    # Interactive mode
    while true; do
        read -p "Carbon Black Server (e.g. cb.example.local): " CB_SERVER
        if validate_server "$CB_SERVER"; then
            break
        fi
    done
    
    while true; do
        read -p "Username: " USERNAME
        if validate_username "$USERNAME"; then
            break
        fi
    done
    
    while true; do
        read -s -p "Password: " PASSWORD_INPUT
        echo ""
        if get_password "$PASSWORD_INPUT"; then
            break
        fi
    done
    
    while true; do
        read -p "Output file name [sensor-installer-linux.tar.gz]: " OUTPUT
        OUTPUT=${OUTPUT:-sensor-installer-linux.tar.gz}
        if validate_output "$OUTPUT"; then
            break
        fi
    done
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' command is required but not installed. Please install jq to continue."
    exit 1
fi

# Get API token
echo "Authenticating to Carbon Black server..."
TOKEN=$(curl -s -X POST "https://$CB_SERVER/api/v1/auth" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" | jq -r '.token')

# Cleanup password immediately after use
unset PASSWORD

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Failed to obtain API token. Please check your credentials and server address."
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
    # Display file size
    file_size=$(du -h "$OUTPUT" | cut -f1)
    echo "File size: $file_size"
else
    echo "Error: Download failed or file is empty."
    exit 1
fi

# Cleanup token
unset TOKEN
