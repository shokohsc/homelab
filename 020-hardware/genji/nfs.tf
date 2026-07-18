# data "proxmox_file" "nfs_cloud_config" {
#   node_name    = var.node_name
#   datastore_id = "nfs-proxmox-content"
#   content_type = "snippets"
#   file_name    = "nfs-cloud-config.yaml"
# }

# data "proxmox_file" "debian_cloud" {
#   node_name    = var.node_name
#   datastore_id = "nfs-proxmox-content"
#   content_type = "import"
#   file_name    = "debian-12-genericcloud-amd64.qcow2"
# }

# resource "proxmox_virtual_environment_vm" "nfs_server" {
#   description = "Managed by OpenTofu"
#   name        = "${var.node_name}-nfs"
#   node_name   = var.node_name

#   agent {
#     enabled = false
#   }

#   cpu {
#     cores = 1
#   }

#   memory {
#     dedicated = 256
#   }

#   disk {
#     datastore_id = "local-lvm"
#     import_from  = data.proxmox_file.debian_cloud.id
#     interface    = "scsi0"
#     size         = 8
#   }

#   virtiofs {
#     mapping   = "tank"
#     cache     = "always"
#     direct_io = true
#   }

#   initialization {
#     datastore_id = "local-lvm"
#     ip_config {
#       ipv4 {
#         address = "10.42.60.130/24"
#         gateway = "10.42.60.1"
#       }
#     }
#     user_data_file_id = data.proxmox_file.nfs_cloud_config.id
#   }

#   network_device {
#     bridge  = proxmox_network_linux_bridge.sfpplus.name
#     vlan_id = "60"
#   }

#   operating_system {
#     type = "l26"
#   }

#   started = true

#   startup {
#     order = "5"
#   }

#   tags = [
#     "nfs",
#     "opentofu"
#   ]

#   lifecycle {
#     ignore_changes = [
#       initialization
#     ]
#   }
# }
