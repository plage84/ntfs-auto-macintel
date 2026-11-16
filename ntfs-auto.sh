#!/bin/bash
# ntfs-auto: automatically mounts NTFS drives read-write with ntfs-3g (macFUSE).
# Run continuously by launchd (see local.ntfs-auto.plist). Log: /var/log/ntfs-auto.log
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/local/bin:/usr/local/bin:/opt/homebrew/bin
LOG=/var/log/ntfs-auto.log
TRIES=""; MOUNTED=""; EJECTED=""
echo "$(date) service started" >> "$LOG"
while true; do
  list=$(diskutil list | awk '/Windows_NTFS|Microsoft Basic Data/ {print $NF}')
  # forget ejected drives once they have been unplugged
  new=""
  for e in $EJECTED; do echo "$list" | grep -qx "$e" && new="$new $e"; done
  EJECTED="$new"
  found=0
  for id in $list; do
    d="/dev/$id"
    case " $EJECTED " in *" $id "*) continue;; esac
    info=$(diskutil info "$d" 2>/dev/null) || continue
    # skip exFAT / FAT (same partition type as NTFS)
    echo "$info" | grep -i "Personality" | grep -qi "fat" && continue
    found=1
    # stop macOS from auto-mounting this drive again (one fstab line per drive)
    uuid=$(echo "$info" | awk -F': +' '/Volume UUID/ {print $2}')
    if [ -n "$uuid" ] && ! grep -q "UUID=$uuid" /etc/fstab 2>/dev/null; then
      echo "UUID=$uuid none ntfs rw,noauto" >> /etc/fstab
      echo "$(date) fstab: added drive $uuid" >> "$LOG"
    fi
    if pgrep -f "ntfs-3g $d " >/dev/null; then
      # already mounted by ntfs-3g: remove any read-only duplicate mounted by macOS
      mount | sed -n "s#^ntfs://$id/.* on \(.*\) (lifs.*#\1#p" | while read -r mp; do
        echo "$(date) removing read-only duplicate mount: $mp" >> "$LOG"
        diskutil unmount "$mp" >> "$LOG" 2>&1
      done
      continue
    fi
    # the ntfs-3g mount is gone but the drive is still plugged in: the user ejected it
    case " $MOUNTED " in *" $id "*)
      echo "$(date) $id ejected by the user: ejecting the disk" >> "$LOG"
      diskutil eject "/dev/${id%s[0-9]*}" >> "$LOG" 2>&1
      MOUNTED=$(echo " $MOUNTED " | sed "s/ $id / /")
      EJECTED="$EJECTED $id"
      continue;;
    esac
    # at most 3 failed attempts per drive
    n=$(echo "$TRIES" | grep -o "$id;" | wc -l | tr -d ' ')
    [ "$n" -ge 3 ] && continue
    name=$(echo "$info" | awk -F': +' '/Volume Name/ {print $2}')
    name=${name:-NTFS-$id}
    echo "$(date) mounting $d ($name)" >> "$LOG"
    diskutil unmount "$d" >> "$LOG" 2>&1
    mkdir -p "/Volumes/$name"
    ntfs-3g "$d" "/Volumes/$name" -o local,allow_other,auto_xattr,no_detach,volname="$name" </dev/null >> "$LOG" 2>&1 &
    sleep 3
    if mount | grep -q "^$d on"; then
      MOUNTED="$MOUNTED $id"
    else
      echo "$(date) mount failed for $d" >> "$LOG"
      TRIES="$TRIES$id;"
    fi
  done
  if [ "$found" -eq 0 ]; then TRIES=""; MOUNTED=""; fi
  sleep 5
done
