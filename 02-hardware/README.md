# Homelab Project

## Kubernetes Cluster
- **Control Planes**: Three Intel NUC 7th Gen i3 nodes running Talos Linux.
- **Workers**:
  - One 8th Gen Intel i3 node.
  - One 2U chassis with a Ryzen 7 1700X CPU and 16GB RAM.
  - Additional worker VMs that can be scaled in or out on three Proxmox nodes.

## Proxmox Nodes
- **Primary Node**: Dell PowerEdge R730 with:
  - Nvidia Tesla P40.
  - Intel ARC A310.
  - Eight 6TB spinning disks configured as a ZFS pool (6 disks as RAIDZ2 and 2 spares).
  - 256GB RAM.
  - Two Xeon E5-2699 v3 CPUs.
- **Secondary Nodes**: Two 2U chassis with:
  - Nvidia Tesla P4.
  - Intel ARC A310.
  - Eight 6TB spinning disks configured as a ZFS pool (6 disks as RAIDZ2 and 2 spares).
  - 64GB RAM.
  - Ryzen R9 3950X CPUs.

## Terraform Postgres Backend

```
docker compose up -d
```

## References

- [PostgreSQL Backend for Terraform](https://www.phillipsj.net/posts/postgresql-backend-for-terraform/)