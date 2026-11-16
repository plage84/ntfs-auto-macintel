#!/bin/bash
# Uninstalls automatic NTFS mounting.
sudo launchctl unload /Library/LaunchDaemons/local.ntfs-auto.plist 2>/dev/null || true
sudo pkill ntfs-3g 2>/dev/null || true
sudo rm -f /Library/LaunchDaemons/local.ntfs-auto.plist /usr/local/bin/ntfs-auto.sh /var/log/ntfs-auto.log
cat <<'EOF'
Service removed.

The script added lines like "UUID=... none ntfs rw,noauto" to /etc/fstab (one per NTFS drive it has seen).
To let macOS auto-mount those drives again, delete them:   sudo vifs
EOF
