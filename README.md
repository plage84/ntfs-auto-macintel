# ntfs-auto-mac

Montage **automatique en lecture-écriture** des disques NTFS sur macOS, avec [ntfs-3g](https://github.com/tuxera/ntfs-3g) et [macFUSE](https://macfuse.github.io). Tu branches le disque, il apparaît en lecture-écriture, sans toucher au Terminal.

Pensé et testé pour un **iMac Intel sous macOS Monterey 12**, où Homebrew n'est plus pris en charge (installation via MacPorts). Devrait aussi servir sur d'autres versions, mais je ne l'ai pas testé ailleurs.

## Ce que ça fait

- Un petit service (`launchd`) surveille les disques toutes les 5 secondes.
- Pour chaque partition NTFS (les exFAT/FAT sont ignorées) : démontage du montage en lecture seule de macOS, puis montage avec ntfs-3g.
- Ajoute dans `/etc/fstab` une ligne `UUID=… none ntfs rw,noauto` par disque, pour que macOS arrête de le monter tout seul. Seul le tout premier branchement d'un disque montre quelques va-et-vient.
- Option `auto_xattr` : évite l'erreur du Finder « impossible de terminer l'opération » (attributs étendus non gérés par NTFS). Des fichiers cachés `._…` peuvent apparaître.
- Si tu éjectes le disque dans le Finder, le script l'éjecte vraiment, et ne le remonte pas avant que tu l'aies débranché puis rebranché. (Ce comportement n'a pas encore été validé de bout en bout sur la machine de test.)

## Prérequis

1. **ntfs-3g** :
   - Intel / ancien macOS : [MacPorts](https://www.macports.org), puis `sudo port install ntfs-3g` (installe aussi macFUSE).
   - Autrement : Homebrew, puis `brew install gromgit/fuse/ntfs-3g-mac`.
2. **macFUSE** autorisé dans *Réglages Système > Confidentialité et sécurité* (redémarrage nécessaire). Avec MacPorts, il faut aussi lancer :
   `sudo ln -fsn /opt/local/Library/Filesystems/macfuse.fs /Library/Filesystems/macfuse.fs`

## Installation

```
git clone https://github.com/plage84/ntfs-auto-mac.git
cd ntfs-auto-mac
./install.sh
```

Puis, **une seule fois**, dans *Réglages Système > Confidentialité et sécurité > Accès complet au disque*, ajoute (bouton **+**, puis ⌘⇧G pour saisir le chemin) :

- `ntfs-3g` (par exemple `/opt/local/bin/ntfs-3g`)
- `/bin/bash`

Sans cela, le journal affiche `Operation not permitted`. Donner l'accès complet au disque à `bash` est large : il s'applique à tous les scripts bash lancés par le système. À toi de juger si cela te convient.

## Utilisation

Branche le disque, attends 20 secondes. Journal : `cat /var/log/ntfs-auto.log`.

Quelques conseils :
- Éjecte toujours le disque avant de le débrancher.
- Sous Windows, désactive le « démarrage rapide », sinon le disque reste en hibernation et ntfs-3g refuse l'écriture. En cas de disque « sale » : `chkdsk` sous Windows, ou `sudo ntfsfix /dev/diskXsY`.

## Désinstallation

```
./uninstall.sh
```

Pense à retirer les lignes ajoutées dans `/etc/fstab` (`sudo vifs`).

## Limites connues

- Le journal grossit (messages répétitifs de macFUSE) : `sudo truncate -s 0 /var/log/ntfs-auto.log`.
- Les avertissements `objc … implemented in both` dans le journal viennent de deux copies de macFUSE visibles par le système. Ils n'ont pas empêché le montage sur la machine de test.
- BitLocker n'est pas pris en charge.
- Cela modifie `/etc/fstab` : relis le script avant de l'installer.

## Licence

MIT
