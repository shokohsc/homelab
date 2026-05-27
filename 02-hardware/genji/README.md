## Storage (create zfs pool from ubuntu beforehand)
    sudo zpool create -f -o ashift=12 -o autotrim=on \
      -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
      tank \
      raidz2 \
        /dev/disk/by-id/wwn-0x5000cca2559edb8c \
        /dev/disk/by-id/wwn-0x5000cca2553f3fac \
        /dev/disk/by-id/wwn-0x5000cca2559e2af8 \
        /dev/disk/by-id/wwn-0x5000cca25544326c \
        /dev/disk/by-id/wwn-0x5000cca2554890b4 \
        /dev/disk/by-id/wwn-0x5000cca255489db4 \
      spare \
        /dev/disk/by-id/wwn-0x5000cca25544836c \
        /dev/disk/by-id/wwn-0x5000cca2559e2bb8
    
    sudo zfs create -o mountpoint=/mnt/tank tank/tank

    sudo mkdir /mnt/nvme && sudo mount -t exfat /dev/disk/by-uuid/C551-E0A6 /mnt/nvme

    sudo $(which rsyncy) -av /mnt/nvme/ /mnt/tank/
    
    sudo zpool scrub tank

wwn-0x5000cca2559edb8c -> sda
wwn-0x5000cca2553f3fac -> sdb
wwn-0x5000cca2559e2af8 -> sdc
wwn-0x5000cca25544326c -> sdd
wwn-0x5000cca2554890b4 -> sde
wwn-0x5000cca255489db4 -> sdf
wwn-0x5000cca25544836c -> sdg
wwn-0x5000cca2559e2bb8 -> sdh

sudo dd if=/dev/zero of=/dev/sda  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdb  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdc  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdd  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sde  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdf  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdg  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdh  bs=512  count=1
