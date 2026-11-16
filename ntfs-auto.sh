#!/bin/bash
# ntfs-auto : monte automatiquement les disques NTFS en lecture-écriture avec ntfs-3g (macFUSE).
# Lancé en continu par launchd (voir local.ntfs-auto.plist). Journal : /var/log/ntfs-auto.log
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/local/bin:/usr/local/bin:/opt/homebrew/bin
LOG=/var/log/ntfs-auto.log
TRIES=""; MOUNTED=""; EJECTED=""
echo "$(date) service démarré" >> "$LOG"
while true; do
  list=$(diskutil list | awk '/Windows_NTFS|Microsoft Basic Data/ {print $NF}')
  # oublier les disques éjectés qui ont été débranchés
  new=""
  for e in $EJECTED; do echo "$list" | grep -qx "$e" && new="$new $e"; done
  EJECTED="$new"
  found=0
  for id in $list; do
    d="/dev/$id"
    case " $EJECTED " in *" $id "*) continue;; esac
    info=$(diskutil info "$d" 2>/dev/null) || continue
    # on ignore exFAT / FAT (même type de partition que NTFS)
    echo "$info" | grep -i "Personality" | grep -qi "fat" && continue
    found=1
    # empêche macOS de remonter ce disque tout seul (une ligne fstab par disque)
    uuid=$(echo "$info" | awk -F': +' '/Volume UUID/ {print $2}')
    if [ -n "$uuid" ] && ! grep -q "UUID=$uuid" /etc/fstab 2>/dev/null; then
      echo "UUID=$uuid none ntfs rw,noauto" >> /etc/fstab
      echo "$(date) fstab: ajout du disque $uuid" >> "$LOG"
    fi
    if pgrep -f "ntfs-3g $d " >/dev/null; then
      # déjà monté par ntfs-3g : on retire un éventuel doublon en lecture seule de macOS
      mount | sed -n "s#^ntfs://$id/.* on \(.*\) (lifs.*#\1#p" | while read -r mp; do
        echo "$(date) retrait du montage lecture seule: $mp" >> "$LOG"
        diskutil unmount "$mp" >> "$LOG" 2>&1
      done
      continue
    fi
    # le montage ntfs-3g a disparu alors que le disque est branché : éjection par l'utilisateur
    case " $MOUNTED " in *" $id "*)
      echo "$(date) $id éjecté par l'utilisateur: éjection du disque" >> "$LOG"
      diskutil eject "/dev/${id%s[0-9]*}" >> "$LOG" 2>&1
      MOUNTED=$(echo " $MOUNTED " | sed "s/ $id / /")
      EJECTED="$EJECTED $id"
      continue;;
    esac
    # pas plus de 3 tentatives ratées par disque
    n=$(echo "$TRIES" | grep -o "$id;" | wc -l | tr -d ' ')
    [ "$n" -ge 3 ] && continue
    name=$(echo "$info" | awk -F': +' '/Volume Name/ {print $2}')
    name=${name:-NTFS-$id}
    echo "$(date) montage de $d ($name)" >> "$LOG"
    diskutil unmount "$d" >> "$LOG" 2>&1
    mkdir -p "/Volumes/$name"
    ntfs-3g "$d" "/Volumes/$name" -o local,allow_other,auto_xattr,no_detach,volname="$name" </dev/null >> "$LOG" 2>&1 &
    sleep 3
    if mount | grep -q "^$d on"; then
      MOUNTED="$MOUNTED $id"
    else
      echo "$(date) échec du montage de $d" >> "$LOG"
      TRIES="$TRIES$id;"
    fi
  done
  if [ "$found" -eq 0 ]; then TRIES=""; MOUNTED=""; fi
  sleep 5
done
