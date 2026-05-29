## Storage (create zfs pool from ubuntu beforehand)
    sudo zpool create -f -o ashift=12 -o autotrim=on \
      -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
      tank \
      raidz2 \
        /dev/disk/by-id/wwn-0x5000cca2559ee368 \
        /dev/disk/by-id/wwn-0x5000c500843cd9bf \
        /dev/disk/by-id/wwn-0x5000cca255456054 \
        /dev/disk/by-id/wwn-0x5000c50084480e57 \
        /dev/disk/by-id/wwn-0x5000cca255480ce4 \
        /dev/disk/by-id/wwn-0x5000c500843cdf9b \
      spare \
        /dev/disk/by-id/wwn-0x5000cca255449f70 \
        /dev/disk/by-id/wwn-0x5000c500843d5717
    
    sudo zfs create -o mountpoint=/mnt/tank tank/tank

    sudo mkdir /mnt/nvme && sudo mount -t exfat /dev/disk/by-uuid/C551-E0A6 /mnt/nvme

    sudo $(which rsyncy) -av /mnt/nvme/ /mnt/tank/
    
    sudo zpool scrub tank

wwn-0x5000cca2559ee368 -> sda
wwn-0x5000c500843cd9bf -> sdb
wwn-0x5000cca255456054 -> sdc
wwn-0x5000c50084480e57 -> sdd
wwn-0x5000cca255480ce4 -> sde
wwn-0x5000c500843cdf9b -> sdf
wwn-0x5000cca255449f70 -> sdg
wwn-0x5000c500843d5717 -> sdh

sudo dd if=/dev/zero of=/dev/sda  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdb  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdc  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdd  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sde  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdf  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdg  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdh  bs=512  count=1
