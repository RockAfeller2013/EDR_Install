#!/bin/bash
# Usage: ./download_cb_sensor.sh <CB_SERVER> <API_TOKEN> <OS_TYPE> [GROUP_ID] [OUTPUT_FILE]

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <CB_SERVER> <API_TOKEN> <OS_TYPE> [GROUP_ID] [OUTPUT_FILE]"
    echo ""
    echo "OS_TYPE options: linux, windows-exe, windows-msi, osx"
    echo "GROUP_ID: defaults to 1 (default group)"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.30 YOUR_API_TOKEN linux"
    echo "  $0 192.168.1.30 YOUR_API_TOKEN windows-exe 1 sensor.zip"
    echo "  $0 192.168.1.30 YOUR_API_TOKEN osx 2"
    echo ""
    echo "To get an API token:"
    echo "1. Log into Carbon Black web console"
    echo "2. Go to User Management > API Keys"
    echo "3. Create a new API key"
    exit 1
fi

CB_SERVER="$1"
API_TOKEN="$2"
OS_TYPE="$3"
GROUP_ID="${4:-1}"

# Set default output filename and endpoint based on OS type
case "$OS_TYPE" in
    linux)
        OUTPUT="${5:-sensor-installer-linux.tar.gz}"
        ENDPOINT="https://$CB_SERVER/api/v1/group/$GROUP_ID/installer/linux"
        ;;
    windows-exe)
        OUTPUT="${5:-sensor-installer-windows.zip}"
        ENDPOINT="https://$CB_SERVER/api/v1/group/$GROUP_ID/installer/windows/exe"
        ;;
    windows-msi)
        OUTPUT="${5:-sensor-installer-windows.zip}"
        ENDPOINT="https://$CB_SERVER/api/v1/group/$GROUP_ID/installer/windows/msi"
        ;;
    osx)
        OUTPUT="${5:-sensor-installer-osx.zip}"
        ENDPOINT="https://$CB_SERVER/api/v1/group/$GROUP_ID/installer/osx"
        ;;
    *)
        echo "Error: Invalid OS_TYPE. Must be: linux, windows-exe, windows-msi, or osx"
        exit 1
        ;;
esac

echo "Downloading $OS_TYPE sensor installer for group $GROUP_ID..."
curl -k -f -H "X-Auth-Token: $API_TOKEN" \
     -o "$OUTPUT" \
     "$ENDPOINT"

if [ $? -eq 0 ] && [ -s "$OUTPUT" ]; then
    echo "Download complete: $OUTPUT"
    echo "File size: $(du -h "$OUTPUT" | cut -f1)"
else
    echo "Error: Download failed or file is empty."
    exit 1
fi
