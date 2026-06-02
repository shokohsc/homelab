## Storage (create zfs pool from ubuntu beforehand)
    zpool create -f -o ashift=12 -o autotrim=on \
      -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
      tank \
      raidz2 \
        /dev/disk/by-id/scsi-35000cca255489568 \
        /dev/disk/by-id/scsi-35000cca2554699a4 \
        /dev/disk/by-id/scsi-35000cca255429d78 \
        /dev/disk/by-id/scsi-35000cca2559e28e8 \
        /dev/disk/by-id/scsi-35000cca255455440 \
        /dev/disk/by-id/scsi-35000cca2554557f0 \
      spare \
        /dev/disk/by-id/scsi-35000cca2553f3b7c \
        /dev/disk/by-id/scsi-35000cca2554262f0
    
    sudo zfs create -o mountpoint=/mnt/tank tank/tank

    sudo mkdir /mnt/nvme && sudo mount -t exfat /dev/disk/by-uuid/C551-E0A6 /mnt/nvme

    sudo $(which rsyncy) -av /mnt/nvme/ /mnt/tank/
    
    sudo zpool scrub tank

wwn-0x5000cca255489568 -> sda
wwn-0x5000cca2554699a4 -> sdb
wwn-0x5000cca255429d78 -> sdc
wwn-0x5000cca2559e28e8 -> sdd
wwn-0x5000cca255455440 -> sde
wwn-0x5000cca2554557f0 -> sdf
wwn-0x5000cca2553f3b7c -> sdg
wwn-0x5000cca2554262f0 -> sdh

https://github.com/laktak/rsyncy?tab=readme-ov-file#installation

https://stanislavs.org/adding-disks-by-label-in-zfs-and-making-them-stick-around/

https://memo-linux.com/proxmox-backup-server-stockage-zfs/

https://ubuntu.com/tutorials/setup-zfs-storage-pool#1-overview

https://cr0x.net/fr/proxmox-zfs-degraded-remplacer-disque/

sudo dd if=/dev/zero of=/dev/sda  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdb  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdc  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdd  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sde  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdf  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdg  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdh  bs=512  count=1

 /dev/disk/by-id/scsi-35000cca255489568 -> ../../sda 
 /dev/disk/by-id/scsi-35000cca2554699a4 -> ../../sdb 
 /dev/disk/by-id/scsi-35000cca255429d78 -> ../../sdc 
 /dev/disk/by-id/scsi-35000cca2559e28e8 -> ../../sdd 
 /dev/disk/by-id/scsi-35000cca255455440 -> ../../sde 
 /dev/disk/by-id/scsi-35000cca2554557f0 -> ../../sdf 
 /dev/disk/by-id/scsi-35000cca2553f3b7c -> ../../sdg 
 /dev/disk/by-id/scsi-35000cca2554262f0 -> ../../sdh 

docker run --rm -it --network=host nicolaka/netshoot sh