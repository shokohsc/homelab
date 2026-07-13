provider "proxmox" {
  endpoint      = "${var.proxmox_protocol}://${var.proxmox_host}:${var.proxmox_port}/"
  username      = "${var.proxmox_username}@${var.proxmox_realm}"
  password      = var.proxmox_password
  insecure      = var.ssl_insecure
  random_vm_ids = var.random_vm_ids
}
