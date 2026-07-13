resource "proxmox_oci_image" "itsthenetwork_nfs_server_alpine_latest" {
  node_name    = var.node_name
  datastore_id = "local"
  reference    = "docker.io/itsthenetwork/nfs-server-alpine:latest"
}

resource "proxmox_virtual_environment_container" "itsthenetwork_nfs_server_alpine_container" {
  description = "Managed by OpenTofu"
  node_name   = var.node_name
  operating_system = {
    template_file_id = proxmox_oci_image.itsthenetwork_nfs_server_alpine_latest.id
    type             = "alpine"
  }
  # mount_point {
  #   path   = "/mnt/data"
  #   volume = "tank/my_dataset"
  # }
  network_interface {
    name = "veth0"
  }
  startup {
    order = "5"
  }
  tags = [
    "nfs",
    "opentofu"
  ]
}

# resource "proxmox_virtual_environment_download_file" "ubuntu_2504_lxc_img" {
#   content_type = "vztmpl"
#   datastore_id = "local"
#   node_name = var.node_name
#   url          = "https://mirrors.servercentral.com/ubuntu-cloud-images/releases/25.04/release/ubuntu-25.04-server-cloudimg-amd64-root.tar.xz"
# }
