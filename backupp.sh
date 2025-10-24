#!/bin/bash
# chmod +x cb_backup.sh
# ./cb_backup.sh


BACKUP_DIR="/root/cb-backup-$(date +%F)"
ARCHIVE="/root/cb-backup-$(date +%F).tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Copy main config directories
cp -a /etc/cb "$BACKUP_DIR/"
cp -a /usr/share/cb "$BACKUP_DIR/"
cp -a /var/lib/cb "$BACKUP_DIR/"

# Optional: service definitions
cp -a /etc/systemd/system/cb* "$BACKUP_DIR/" 2>/dev/null
cp -a /opt/carbonblack "$BACKUP_DIR/" 2>/dev/null

# Compress backup
tar czvf "$ARCHIVE" -C /root "$(basename "$BACKUP_DIR")"

# Secure permissions
chmod 600 "$ARCHIVE"

echo "Backup completed: $ARCHIVE"
