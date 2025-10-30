#!/bin/bash
# ==========================================================
# Proxmox VM Build Script for Carbon Black EDR on Rocky Linux
# Usage:
#   ./build_cb_vm.sh <VMID> [hostname] [ip/cidr]
#
# Examples:
#   ./build_cb_vm.sh 202
#   ./build_cb_vm.sh 203 cbresponse2 192.168.1.50/24
# ==========================================================
# curl -sSL https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/license/auto_install_EDR.sh | bash -s -- 203 edr-node 192.168.1.51/24


set -e

# --- Input Validation ---
if [ -z "$1" ]; then
  echo "Usage: $0 <VMID> [hostname] [ip/cidr]"
  exit 1
fi

VMID="$1"
HOSTNAME="${2:-cbresponse}"
IP_ADDR="${3:-192.168.1.30/24}"

# --- Configuration Defaults ---
VM_NAME="${HOSTNAME}-${VMID}"
MEMORY="32768"
CORES="4"
BRIDGE="vmbr0"
GATEWAY="192.168.1.99"
NAMESERVERS="1.1.1.1,8.8.8.8"
STORAGE="local-lvm"
QCOW_DIR="/var/lib/vz/images/${VMID}"
QCOW_PATH="${QCOW_DIR}/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2"
CLOUDINIT_SNIPPET="/var/lib/vz/snippets/user-data.yaml"
ROCKY_URL="https://dl.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2"

echo "==========================================="
echo " Proxmox VM Build Script"
echo "-------------------------------------------"
echo " VMID:       ${VMID}"
echo " Hostname:   ${HOSTNAME}"
echo " IP Address: ${IP_ADDR}"
echo " Gateway:    ${GATEWAY}"
echo "==========================================="

# --- Create image directory ---
echo "[+] Creating image directory: ${QCOW_DIR}"
mkdir -p "${QCOW_DIR}"

# --- Download Rocky Linux QCOW2 image (only if missing) ---
if [ ! -f "$QCOW_PATH" ]; then
  echo "[+] Downloading Rocky Linux 8 Cloud image..."
  curl -L -o "$QCOW_PATH" "$ROCKY_URL"
else
  echo "[=] Using existing Rocky Linux image at ${QCOW_PATH}"
fi

# --- Download Cloud-init config (auto_install.yaml) ---
echo "[+] Fetching Cloud-init configuration..."
curl -fsSL -o "$CLOUDINIT_SNIPPET" \
  https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/refs/heads/main/license/auto_install.yaml

# --- Create the VM ---
echo "[+] Creating VM ID: ${VMID}"
qm create "$VMID" \
  --name "$VM_NAME" \
  --memory "$MEMORY" \
  --cores "$CORES" \
  --net0 virtio,bridge="$BRIDGE" \
  --scsihw virtio-scsi-pci \
  --ostype l26 \
  --cpu host \
  --serial0 socket \
  --agent 1 \
  --boot order=scsi0

# --- Import the QCOW2 disk ---
echo "[+] Importing QCOW2 disk..."
qm importdisk "$VMID" "$QCOW_PATH" "$STORAGE"

# --- Configure disk and cloud-init ---
echo "[+] Attaching disk and Cloud-init configuration..."
qm set "$VMID" --scsi0 "$STORAGE:vm-${VMID}-disk-0"
qm set "$VMID" --ide2 local:cloudinit
qm set "$VMID" --boot order=scsi0
qm set "$VMID" --cicustom "user=local:snippets/user-data.yaml"
qm set "$VMID" --nameserver "$NAMESERVERS"
qm set "$VMID" --ipconfig0 "ip=${IP_ADDR},gw=${GATEWAY}"
qm set "$VMID" --ciuser root --cipassword Password1!
qm set "$VMID" --hostname "$HOSTNAME"

# --- Update Cloud-init ---
echo "[+] Updating Cloud-init configuration..."
qm cloudinit update "$VMID"

# --- Display configuration ---
echo "[+] VM Configuration complete:"
qm config "$VMID"

echo "✅ VM ${VMID} (${VM_NAME}) ready to start."
echo "Use 'qm start ${VMID}' to boot the VM."
