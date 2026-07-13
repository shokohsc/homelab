variable "proxmox_protocol" {
  type        = string
  default     = "http"
  description = "Proxmox node protocol"
}

variable "proxmox_host" {
  type        = string
  default     = "example.com"
  description = "Proxmox node host"
}

variable "proxmox_port" {
  type        = string
  default     = "8006"
  description = "Proxmox node port"
}

variable "proxmox_username" {
  type        = string
  default     = "opentofu"
  description = "Proxmox node account username"
}

variable "proxmox_password" {
  type        = string
  default     = "opentofu"
  description = "Proxmox node account password"
}

variable "proxmox_realm" {
  type        = string
  default     = "pam"
  description = "Proxmox node account realm"
}

variable "ssl_insecure" {
  type        = bool
  default     = false
  description = "Proxmox ssl connection insecure"
}

variable "node_name" {
  type        = string
  default     = "genji"
  description = "Proxmox node name"
}

variable "random_vm_ids" {
  type        = bool
  default     = true
  description = "Random VM IDs to prevent conflicts"
}

variable "proxmox_linux_bridge_vids" {
  type        = string
  default     = "1"
  description = "Proxmox linux bridge vlan ids"
}

variable "proxmox_linux_bridge_vlan_aware" {
  type        = bool
  default     = true
  description = "Proxmox linux bridge vlan aware"
}

variable "proxmox_linux_bridge_ports" {
  type        = list(string)
  default     = ["eth0"]
  description = "Proxmox linux bridge ports"
}
