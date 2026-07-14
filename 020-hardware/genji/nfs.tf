resource "proxmox_oci_image" "nfs_server" {
  node_name    = var.node_name
  datastore_id = "local"
  reference    = "ghcr.io/shokohsc/nfs-ganesha:4.4.1"
  # reference    = "docker.io/izdock/nfs-ganesha:4.0.12"
  # reference    = "docker.io/izdock/nfs-ganesha:3.4"
}

resource "proxmox_virtual_environment_container" "nfs_server" {
  description  = "Managed by OpenTofu"
  node_name    = var.node_name
  unprivileged = true
  environment_variables = {
    EXPORT_PATH = "/data"
    PSEUDO_PATH = "/"
    EXPORT_ID = "1"
    PROTOCOLS = "4"
    TRANSPORTS = "TCP"
    SEC_TYPE = "sys"
    SQUASH_MODE = "No_Root_Squash"
    GRACELESS = "true"
    GRACE_PERIOD = "90"
    ACCESS_TYPE = "RW"
    CLIENT_LIST = "10.42.0.0/16"
    DISABLE_ACL = "true"
    ANON_USER = "nobody"
    ANON_GROUP = "nogroup"
    GANESHA_CONFIG = "/etc/ganesha/ganesha.conf"
    GANESHA_LOGFILE = "/dev/stdout"
    LOG_LEVEL = "INFO"
    LOG_COMPONENT = "ALL=INFO;"
  }
  # idmap {
  #   type = "uid"
  #   container_id = "0"
  #   host_id = "1000"
  #   size = "65534"
  # }
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
    hostname = "${var.node_name}-nfs"
    dns {
      servers = ["10.42.60.1"]
    }
    ip_config {
      ipv4 {
        address = "10.42.60.102/24"
        gateway = "10.42.60.1"
      }
    }
  }
  network_interface {
    name         = "eth0"
    bridge       = proxmox_network_linux_bridge.sfpplus.name
    host_managed = true
    vlan_id      = "60"
  }
  startup {
    order = "5"
  }
  tags = [
    "nfs",
    "opentofu"
  ]

  lifecycle {
    ignore_changes = [
      initialization[0].entrypoint,
      console
      # environment_variables
    ]
  }
}
