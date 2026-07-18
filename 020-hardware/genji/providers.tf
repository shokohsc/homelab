############################################
##             Provider Config            ##
############################################

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
  }
  required_version = ">= 1.5.0"
}

provider "proxmox" {
  endpoint      = "${var.proxmox_protocol}://${var.proxmox_host}:${var.proxmox_port}/"
  username      = "${var.proxmox_username}@${var.proxmox_realm}"
  password      = var.proxmox_password
  insecure      = var.ssl_insecure
  random_vm_ids = var.random_vm_ids

  ssh {
    username = var.proxmox_username
    password = var.proxmox_password
  }
}
