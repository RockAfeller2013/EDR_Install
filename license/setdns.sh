#!/bin/bash

# Set your desired DNS servers
DNS_SERVERS="1.1.1.1 8.8.8.8"

# Get all non-loopback connections
CONNECTIONS=$(nmcli -t -f NAME,DEVICE connection show | grep -v ":lo" | cut -d: -f1 | sort | uniq)

if [ -z "$CONNECTIONS" ]; then
  echo "❌ No valid network connections found."
  exit 1
fi

for CON in $CONNECTIONS; do
  echo "🔧 Setting DNS for connection: $CON"
  nmcli connection modify "$CON" ipv4.dns "$DNS_SERVERS"
  nmcli connection modify "$CON" ipv4.ignore-auto-dns yes
  nmcli connection up "$CON"
done

echo "✅ DNS configured for all connections."
