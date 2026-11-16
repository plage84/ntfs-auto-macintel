#!/bin/bash
# Installe le montage automatique NTFS (lecture-écriture) sur macOS.
# Usage : ./install.sh   (demande ton mot de passe admin)
set -e
cd "$(dirname "$0")"

if [ "$(uname)" != "Darwin" ]; then echo "Ce script est prévu pour macOS."; exit 1; fi

NTFS3G=""
for p in /opt/local/bin/ntfs-3g /usr/local/bin/ntfs-3g /opt/homebrew/bin/ntfs-3g; do
  [ -x "$p" ] && NTFS3G="$p" && break
done
if [ -z "$NTFS3G" ]; then
  echo "ntfs-3g est introuvable. Installe-le d'abord :"
  echo "  - Mac Intel / ancien macOS : MacPorts (macports.org) puis  sudo port install ntfs-3g"
  echo "  - Sinon : Homebrew puis    brew install gromgit/fuse/ntfs-3g-mac"
  echo "et installe macFUSE (macfuse.github.io), puis autorise-le dans Réglages Système > Confidentialité et sécurité."
  exit 1
fi
echo "ntfs-3g trouvé : $NTFS3G"

echo "Installation du script et du service (mot de passe admin demandé)..."
sudo mkdir -p /usr/local/bin
sudo cp ntfs-auto.sh /usr/local/bin/ntfs-auto.sh
sudo chmod +x /usr/local/bin/ntfs-auto.sh
sudo launchctl unload /Library/LaunchDaemons/local.ntfs-auto.plist 2>/dev/null || true
sudo cp local.ntfs-auto.plist /Library/LaunchDaemons/local.ntfs-auto.plist
sudo chown root:wheel /Library/LaunchDaemons/local.ntfs-auto.plist
sudo chmod 644 /Library/LaunchDaemons/local.ntfs-auto.plist
sudo launchctl load -w /Library/LaunchDaemons/local.ntfs-auto.plist

cat <<'EOF'

Service installé.

À faire UNE FOIS dans Réglages Système > Confidentialité et sécurité > Accès complet au disque :
  ajouter  ntfs-3g  et  /bin/bash   (bouton +, puis Cmd+Maj+G pour saisir le chemin)
Sans cette autorisation, le service reçoit "Operation not permitted".

Ensuite : branche un disque NTFS, attends 20 secondes, il se monte en lecture-écriture.
Journal : cat /var/log/ntfs-auto.log
EOF
