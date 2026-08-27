# Storage (create zfs pool from ubuntu beforehand)

    zpool create -o ashift=12 -o autotrim=on -m /mnt/tank \
      -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
      tank \
      raidz2 \
        /dev/disk/by-id/scsi-35000c500843cd9bf \
        /dev/disk/by-id/scsi-35000c500843cdf9b \
        /dev/disk/by-id/scsi-35000c50084480e57 \
        /dev/disk/by-id/scsi-35000cca255455440 \
        /dev/disk/by-id/scsi-35000cca2554557f0 \
        /dev/disk/by-id/scsi-35000cca255456054 \
      spare \
        /dev/disk/by-id/scsi-35000cca255489568 \
        /dev/disk/by-id/scsi-35000cca2559ee368
    
    zpool scrub tank

## Exports Zfs pool over nfs

    echo '/mnt/tank *(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)' > /etc/exports
    exportfs -ra
    exportfs -v
    systemctl enable --now nfs-kernel-server

## Zap disks

    dd if=/dev/zero of=/dev/sda  bs=512  count=1

## Disk mapping

    scsi-35000c500843cd9bf -> sda
    scsi-35000c500843cdf9b -> sdf
    scsi-35000c50084480e57 -> sde
    scsi-35000cca255455440 -> sdc
    scsi-35000cca2554557f0 -> sdd
    scsi-35000cca255456054 -> sdb
    scsi-35000cca255489568 -> sdh
    scsi-35000cca2559ee368 -> sdg