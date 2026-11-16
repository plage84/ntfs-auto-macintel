#!/bin/bash
# Installs automatic read-write NTFS mounting on macOS.
# Usage: ./install.sh   (asks for your admin password)
set -e
cd "$(dirname "$0")"

if [ "$(uname)" != "Darwin" ]; then echo "This script is meant for macOS."; exit 1; fi

NTFS3G=""
for p in /opt/local/bin/ntfs-3g /usr/local/bin/ntfs-3g /opt/homebrew/bin/ntfs-3g; do
  [ -x "$p" ] && NTFS3G="$p" && break
done
if [ -z "$NTFS3G" ]; then
  echo "ntfs-3g not found. Install it first:"
  echo "  - Intel Mac / older macOS: MacPorts (macports.org), then  sudo port install ntfs-3g"
  echo "  - Otherwise: Homebrew, then  brew install gromgit/fuse/ntfs-3g-mac"
  echo "and install macFUSE (macfuse.github.io), then allow it in System Settings > Privacy & Security."
  exit 1
fi
echo "ntfs-3g found: $NTFS3G"

echo "Installing the script and the service (admin password required)..."
sudo mkdir -p /usr/local/bin
sudo cp ntfs-auto.sh /usr/local/bin/ntfs-auto.sh
sudo chmod +x /usr/local/bin/ntfs-auto.sh
sudo launchctl unload /Library/LaunchDaemons/local.ntfs-auto.plist 2>/dev/null || true
sudo cp local.ntfs-auto.plist /Library/LaunchDaemons/local.ntfs-auto.plist
sudo chown root:wheel /Library/LaunchDaemons/local.ntfs-auto.plist
sudo chmod 644 /Library/LaunchDaemons/local.ntfs-auto.plist
sudo launchctl load -w /Library/LaunchDaemons/local.ntfs-auto.plist

cat <<'EOF'

Service installed.

ONE-TIME step in System Settings > Privacy & Security > Full Disk Access:
  add  ntfs-3g  and  /bin/bash   (click +, then press Cmd+Shift+G to type the path)
Without it the service gets "Operation not permitted".

Then plug in an NTFS drive and wait about 20 seconds: it mounts read-write.
Log: cat /var/log/ntfs-auto.log
EOF
