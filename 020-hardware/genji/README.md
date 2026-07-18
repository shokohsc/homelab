# Storage (create zfs pool from ubuntu beforehand)

    zpool create -o ashift=12 -o autotrim=on -m /mnt/tank \
      -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
      tank \
      raidz2 \
        /dev/disk/by-id/scsi-35000cca2559edb8c \
        /dev/disk/by-id/scsi-35000cca2553f3fac \
        /dev/disk/by-id/scsi-35000cca2559e2af8 \
        /dev/disk/by-id/scsi-35000cca2554890b4 \
        /dev/disk/by-id/scsi-35000cca255489db4 \
        /dev/disk/by-id/scsi-35000cca25544836c \
      spare \
        /dev/disk/by-id/scsi-35000cca2559e2bb8 \
        /dev/disk/by-id/scsi-35000c500843d5717
    
    zpool scrub tank

## Exports Zfs pool over nfs

    echo '/mnt/tank *(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)' > /etc/exports
    exportfs -ra
    exportfs -v
    systemctl enable --now nfs-kernel-server

## Zap disks

    dd if=/dev/zero of=/dev/sda  bs=512  count=1

## Disk mapping

    scsi-35000c500843d5717 -> sdh
    scsi-35000cca2553f3fac -> sdb
    scsi-35000cca25544836c -> sdg
    scsi-35000cca2554890b4 -> sde
    scsi-35000cca255489db4 -> sdf
    scsi-35000cca2559e2af8 -> sdc
    scsi-35000cca2559e2bb8 -> sdd
    scsi-35000cca2559edb8c -> sda