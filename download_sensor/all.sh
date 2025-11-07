#!/bin/bash
# Download all sensor types

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <CB_SERVER> <API_TOKEN> [GROUP_ID]"
    exit 1
fi

CB_SERVER="$1"
API_TOKEN="$2"
GROUP_ID="${3:-1}"

declare -A SENSORS=(
    ["linux"]="sensor-installer-linux.tar.gz"
    ["windows-exe"]="sensor-installer-windows-exe.zip"
    ["windows-msi"]="sensor-installer-windows-msi.zip"
    ["osx"]="sensor-installer-osx.zip"
)

for OS_TYPE in "${!SENSORS[@]}"; do
    OUTPUT="${SENSORS[$OS_TYPE]}"
    
    case "$OS_TYPE" in
        linux)
            ENDPOINT="https://$CB_SERVER/api/v1/group/$GROUP_ID/installer/linux"
            ;;
        windows-exe)
            ENDPOINT="https://$CB_SERVER/api/v1/group/$GROUP_ID/installer/windows/exe"
            ;;
        windows-msi)
            ENDPOINT="https://$CB_SERVER/api/v1/group/$GROUP_ID/installer/windows/msi"
            ;;
        osx)
            ENDPOINT="https://$CB_SERVER/api/v1/group/$GROUP_ID/installer/osx"
            ;;
    esac
    
    echo "Downloading $OS_TYPE sensor..."
    curl -k -f -H "X-Auth-Token: $API_TOKEN" -o "$OUTPUT" "$ENDPOINT"
    
    if [ $? -eq 0 ] && [ -s "$OUTPUT" ]; then
        echo "✓ $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
    else
        echo "✗ Failed to download $OS_TYPE sensor"
    fi
    echo ""
done

echo "Download complete!"
