resource "proxmox_oci_image" "itsthenetwork_nfs_server_alpine_latest_oci_image" {
  node_name    = var.node_name
  datastore_id = "local"
  reference    = "docker.io/itsthenetwork/nfs-server-alpine:latest"
}

resource "proxmox_virtual_environment_container" "itsthenetwork_nfs_server_alpine_container" {
  description = "Managed by OpenTofu"
  node_name   = var.node_name
  unprivileged = false
  cpu {
    cores = 1
  }
  memory {
    dedicated = 512
  }
  disk {
    datastore_id = "tank"
    size = 4
  }
  operating_system {
    template_file_id = proxmox_oci_image.itsthenetwork_nfs_server_alpine_latest_oci_image.id
    type             = "alpine"
  }
  features {
    nesting = true
    mount   = ["nfs"]
  }
  initialization {
    hostname = "nfs-server"
  }
  environment_variables = {
    SHARED_DIRECTORY = "/mnt/data"
  }
  mount_point {
    path   = "/mnt/data"
    volume = "/mnt/tank"
  }
  network_interface {
    name    = "veth0"
    bridge  = proxmox_network_linux_bridge.sfpplus.name
    vlan_id = "50"
  }
  started     = true
  startup {
    order = "5"
  }
  tags = [
    "nfs",
    "opentofu"
  ]
}