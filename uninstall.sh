#!/bin/bash
# Désinstalle le montage automatique NTFS.
sudo launchctl unload /Library/LaunchDaemons/local.ntfs-auto.plist 2>/dev/null || true
sudo pkill ntfs-3g 2>/dev/null || true
sudo rm -f /Library/LaunchDaemons/local.ntfs-auto.plist /usr/local/bin/ntfs-auto.sh /var/log/ntfs-auto.log
cat <<'EOF'
Service supprimé.

Le script a ajouté des lignes "UUID=... none ntfs rw,noauto" dans /etc/fstab (une par disque NTFS vu).
Pour que macOS remonte à nouveau ces disques tout seul, supprime-les :   sudo vifs
EOF
