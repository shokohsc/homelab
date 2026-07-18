resource "proxmox_storage_nfs" "backups" {
  id     = "nfs-proxmox-backups"
  nodes  = ["roadhog", "hanzo", "genji"]
  server = "10.42.60.50"
  export = "/backups"

  content          = ["backup"]
  create_base_path = true
  create_subdirs   = true
  options          = "vers=4.2"
}

resource "proxmox_storage_nfs" "content" {
  id     = "nfs-proxmox-content"
  nodes  = ["roadhog", "hanzo", "genji"]
  server = "10.42.60.51"
  export = "/content"

  content          = ["import", "iso", "snippets", "vztmpl"]
  create_base_path = true
  create_subdirs   = true
  options          = "vers=4.2"
}

# resource "proxmox_download_file" "debian_cloud" {
#   content_type = "import"
#   datastore_id = proxmox_storage_nfs.content.id
#   node_name    = var.node_name
#   url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
#   file_name    = "debian-12-genericcloud-amd64.qcow2"
# }

# resource "proxmox_virtual_environment_file" "nfs_cloud_config" {
#   content_type = "snippets"
#   datastore_id = proxmox_storage_nfs.content.id
#   node_name    = var.node_name

#   source_raw {
#     data = <<-EOF
#       #cloud-config
#       hostname: ${var.node_name}-nfs
#       package_update: true
#       packages:
#         - nfs-kernel-server
#       mounts:
#         - [ "tank", "/mnt/pool", "virtiofs", "defaults", "0", "0" ]
#       runcmd:
#         - mkdir -p /mnt/pool
#         - echo '/mnt/pool *(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)' > /etc/exports
#         - exportfs -ra
#         - systemctl enable --now nfs-kernel-server
#     EOF

#     file_name = "nfs-cloud-config.yaml"
#   }
# }