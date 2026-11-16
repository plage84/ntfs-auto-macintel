# ntfs-auto-macintel

**Automatic read-write mounting** of NTFS drives on macOS, using [ntfs-3g](https://github.com/tuxera/ntfs-3g) and [macFUSE](https://macfuse.github.io). Plug in the drive and it shows up read-write, with no Terminal commands.

Built and tested on an **Intel iMac running macOS Monterey 12**, where Homebrew is no longer supported (installation goes through MacPorts). It may work on other versions, but I haven't tested it elsewhere.

## What it does

- A small `launchd` service checks for drives every 5 seconds.
- For each NTFS partition (exFAT/FAT are ignored): it unmounts the read-only mount made by macOS, then mounts the drive with ntfs-3g.
- It adds one `UUID=… none ntfs rw,noauto` line per drive to `/etc/fstab`, so macOS stops mounting it by itself. Only the very first plug-in of a drive shows a few mount/unmount flips.
- The `auto_xattr` option avoids the Finder error "the operation can't be completed" (extended attributes aren't supported by NTFS). Hidden `._…` files may appear.
- If you eject the drive in the Finder, the script really ejects the disk and does not remount it until you unplug and replug it. (This behaviour has not yet been validated end to end on the test machine.)

## Requirements

1. **ntfs-3g**:
   - Intel / older macOS: [MacPorts](https://www.macports.org), then `sudo port install ntfs-3g` (this also installs macFUSE).
   - Otherwise: Homebrew, then `brew install gromgit/fuse/ntfs-3g-mac`.
2. **macFUSE** allowed in *System Settings > Privacy & Security* (a restart is required). With MacPorts you also need:
   `sudo ln -fsn /opt/local/Library/Filesystems/macfuse.fs /Library/Filesystems/macfuse.fs`

## Installation

```
git clone https://github.com/plage84/ntfs-auto-macintel.git
cd ntfs-auto-macintel
./install.sh
```

Then, **once**, in *System Settings > Privacy & Security > Full Disk Access*, add (click **+**, then press ⌘⇧G to type the path):

- `ntfs-3g` (for example `/opt/local/bin/ntfs-3g`)
- `/bin/bash`

Without this, the log shows `Operation not permitted`. Granting Full Disk Access to `bash` is broad: it applies to every bash script run by the system. Decide whether that is acceptable for you.

## Usage

Plug in the drive and wait about 20 seconds. Log: `cat /var/log/ntfs-auto.log`.

Tips:
- Always eject the drive before unplugging it.
- On Windows, turn off "Fast Startup", otherwise the drive stays hibernated and ntfs-3g refuses to write. For a "dirty" drive: run `chkdsk` on Windows, or `sudo ntfsfix /dev/diskXsY`.

## Uninstall

```
./uninstall.sh
```

Remember to remove the lines the script added to `/etc/fstab` (`sudo vifs`).

## Known limitations

- The log grows (repetitive macFUSE messages): `sudo truncate -s 0 /var/log/ntfs-auto.log`.
- The `objc … implemented in both` warnings in the log come from two copies of macFUSE being visible to the system. They did not prevent mounting on the test machine.
- BitLocker is not supported.
- This modifies `/etc/fstab`: read the script before installing it.

## License

MIT
