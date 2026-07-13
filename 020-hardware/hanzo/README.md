## Storage (create zfs pool from ubuntu beforehand)
    zpool create -o ashift=12 -o autotrim=on -m /mnt/tank \
      -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
      tank \
      raidz2 \
        /dev/disk/by-id/scsi-35000cca2559ee368 \
        /dev/disk/by-id/scsi-35000cca255456054 \
        /dev/disk/by-id/scsi-35000cca255480ce4 \
        /dev/disk/by-id/scsi-35000cca255449f70 \
        /dev/disk/by-id/scsi-35000c500843cd9bf \
        /dev/disk/by-id/scsi-35000c50084480e57 \
      spare \
        /dev/disk/by-id/scsi-35000c500843cdf9b \
        /dev/disk/by-id/scsi-35000c500843d5717
    
    zpool scrub tank

dd if=/dev/zero of=/dev/sda  bs=512  count=1

scsi-35000c500843cd9bf -> ../../sde
scsi-35000c500843cdf9b -> ../../sdg
scsi-35000c500843d5717 -> ../../sdh
scsi-35000c50084480e57 -> ../../sdf
scsi-35000cca255449f70 -> ../../sdd
scsi-35000cca255456054 -> ../../sdb
scsi-35000cca255480ce4 -> ../../sdc
scsi-35000cca2559ee368 -> ../../sda