resource "proxmox_oci_image" "nfs_server" {
  node_name    = var.node_name
  datastore_id = "local"
  reference    = "docker.io/izdock/nfs-ganesha:4.0.12-3"
}

resource "proxmox_virtual_environment_container" "nfs_server" {
  description  = "Managed by OpenTofu"
  node_name    = var.node_name
  unprivileged = true
  cpu {
    cores = 1
  }
  memory {
    dedicated = 64
  }
  mount_point {
    path   = "/data"
    volume = "/mnt/tank"
  }
  disk {
    datastore_id = "local-lvm"
    size         = 1
  }
  operating_system {
    template_file_id = proxmox_oci_image.nfs_server.id
    type             = "debian"
  }
  initialization {
    # entrypoint = "/entrypoint.sh /usr/bin/ganesha.nfsd -F -L /dev/stdout -f /etc/ganesha/ganesha.conf"
    hostname = "${var.node_name}-nfs"
    dns {
      servers = ["10.42.60.1"]
    }
    ip_config {
      ipv4 {
        address = "10.42.60.100/24"
        gateway = "10.42.60.1"
      }
    }
  }
  network_interface {
    name    = "eth0"
    bridge  = proxmox_network_linux_bridge.sfpplus.name
    vlan_id = "60"
  }
  startup {
    order = "5"
  }
  tags = [
    "nfs",
    "opentofu"
  ]
}
