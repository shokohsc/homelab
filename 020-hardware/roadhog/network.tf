resource "proxmox_network_linux_bridge" "sfpplus" {
  node_name  = var.node_name
  name       = "vmbr1"
  address    = var.proxmox_linux_bridge_address
  # gateway    = var.proxmox_linux_bridge_gateway
  comment    = "Managed by OpenTofu"
  ports      = var.proxmox_linux_bridge_ports
  vlan_aware = var.proxmox_linux_bridge_vlan_aware
  vids       = var.proxmox_linux_bridge_vids
}
