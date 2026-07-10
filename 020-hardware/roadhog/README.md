## Storage (create zfs pool from ubuntu beforehand)
    zpool create -f -o ashift=12 -o autotrim=on \
      -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
      tank \
      raidz2 \
        /dev/disk/by-id/scsi-35000cca255455440 \
        /dev/disk/by-id/scsi-35000cca2554699a4 \
        /dev/disk/by-id/scsi-35000cca255429d78 \
        /dev/disk/by-id/scsi-35000cca255489568 \
        /dev/disk/by-id/scsi-35000cca2554557f0 \
        /dev/disk/by-id/scsi-35000cca2553f3b7c \
      spare \
        /dev/disk/by-id/scsi-35000cca2559e28e8 \
        /dev/disk/by-id/scsi-35000c500843cdf9b
    
    sudo zfs create -o mountpoint=/mnt/tank tank/tank

    sudo mkdir /mnt/nvme && sudo mount -t exfat /dev/disk/by-uuid/C551-E0A6 /mnt/nvme

    sudo $(which rsyncy) -av /mnt/nvme/ /mnt/tank/
    
    sudo zpool scrub tank

https://github.com/laktak/rsyncy?tab=readme-ov-file#installation

https://stanislavs.org/adding-disks-by-label-in-zfs-and-making-them-stick-around/

https://memo-linux.com/proxmox-backup-server-stockage-zfs/

https://ubuntu.com/tutorials/setup-zfs-storage-pool#1-overview

https://cr0x.net/fr/proxmox-zfs-degraded-remplacer-disque/

https://bpg.sh/docs/resources/virtual_environment_storage_zfspool/

https://forum.level1techs.com/t/zfs-guide-for-starters-and-advanced-users-concepts-pool-config-tuning-troubleshooting/196035/2

https://merox.dev/blog/proxmox-gpu-passthrough/

https://mirceanton.com/posts/setting-up-ceph-in-my-proxmox-cluster/#ceph-in-30-seconds-whats-the-big-deal

sudo dd if=/dev/zero of=/dev/sda  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdb  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdc  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdd  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sde  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdf  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdg  bs=512  count=1
sudo dd if=/dev/zero of=/dev/sdh  bs=512  count=1

scsi-35000cca255455440 sda
scsi-35000cca2554699a4 sdb
scsi-35000cca255429d78 sdc
scsi-35000cca2559e28e8 sdd
scsi-35000cca255489568 sde
scsi-35000cca2554557f0 sdf
scsi-35000cca2553f3b7c sdg
scsi-35000c500843cdf9b sdh

docker run --rm -it --network=host nicolaka/netshoot sh
