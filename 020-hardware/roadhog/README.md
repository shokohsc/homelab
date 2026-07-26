# Storage (create zfs pool from ubuntu beforehand)

    zpool create -o ashift=12 -o autotrim=on -m /mnt/tank \
      -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
      tank \
      raidz2 \
        /dev/disk/by-id/scsi-35000cca2553f3b7c \
        /dev/disk/by-id/scsi-35000cca2554262f0 \
        /dev/disk/by-id/scsi-35000cca255429d78 \
        /dev/disk/by-id/scsi-35000cca25544326c \
        /dev/disk/by-id/scsi-35000cca255449f70 \
        /dev/disk/by-id/scsi-35000cca2554699a4 \
      spare \
        /dev/disk/by-id/scsi-35000cca255480ce4 \
        /dev/disk/by-id/scsi-35000cca2559edb8c
    
    zpool scrub tank

## Exports Zfs pool over nfs

    echo '/mnt/tank *(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)' > /etc/exports
    exportfs -ra
    exportfs -v
    systemctl enable --now nfs-kernel-server

## Zap disks

    dd if=/dev/zero of=/dev/sda  bs=512  count=1

## Disk mapping

    scsi-35000cca2553f3b7c -> sdh
    scsi-35000cca2554262f0 -> sdf
    scsi-35000cca255429d78 -> sdd
    scsi-35000cca25544326c -> sda
    scsi-35000cca255449f70 -> sdc
    scsi-35000cca2554699a4 -> sdb
    scsi-35000cca255480ce4 -> sdg
    scsi-35000cca2559edb8c -> sde

## Refs

    docker run --rm -it --network=host nicolaka/netshoot sh

---

https://github.com/laktak/rsyncy?tab=readme-ov-file#installation

https://stanislavs.org/adding-disks-by-label-in-zfs-and-making-them-stick-around/

https://memo-linux.com/proxmox-backup-server-stockage-zfs/

https://ubuntu.com/tutorials/setup-zfs-storage-pool#1-overview

https://cr0x.net/fr/proxmox-zfs-degraded-remplacer-disque/

https://bpg.sh/docs/resources/virtual_environment_storage_zfspool/

https://forum.level1techs.com/t/zfs-guide-for-starters-and-advanced-users-concepts-pool-config-tuning-troubleshooting/196035/2

https://merox.dev/blog/proxmox-gpu-passthrough/

https://mirceanton.com/posts/setting-up-ceph-in-my-proxmox-cluster/#ceph-in-30-seconds-whats-the-big-deal
