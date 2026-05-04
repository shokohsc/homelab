variable "routeros_protocol" {
  type        = string
  default     = "https"
  description = "Mikrotik router protocol"
}

variable "routeros_host" {
  type        = string
  default     = "example.com"
  description = "Mikrotik router host"
}

variable "routeros_username" {
  type        = string
  default     = "opentofu"
  description = "Mikrotik router account username"
}

variable "routeros_password" {
  type        = string
  default     = "opentofu"
  description = "Mikrotik router account password"
}

variable "routeros_insecure" {
  type        = bool
  default     = false
  description = "Mikrotik router insecure TLS"
}

# Note: This variable is deprecated - use vlan_base_network instead.
# Kept for backward compatibility.
variable "homelab_cidr" {
  type        = string
  default     = "10.42.0.0/16"
  description = "Homelab network CIDR (deprecated - use vlan_base_network)"
}

variable "upstream_primary_dns" {
  type        = string
  default     = "1.1.1.1"
  description = "Primary upstream DNS server"
}

variable "upstream_secondary_dns" {
  type        = string
  default     = "9.9.9.9"
  description = "Secondary upstream DNS server"
}

variable "vlan_base_network" {
  type        = string
  default     = "10.42.0.0"
  description = "Base network for VLAN subnets (e.g., 10.42.0.0 for 10.42.0.0/24, 10.42.1.0/24, etc.)"
}

variable "vlan_filtering" {
  type        = bool
  default     = false
  description = "Bridge VLAN filtering, default is false to prevent locking user out."
}

variable "disable_firewall_rules" {
  type        = bool
  default     = false
  description = "Enable firewall rules boolean, default is false to prevent locking user out."
}

variable "vlan_prefix_length" {
  type        = number
  default     = 24
  description = "CIDR prefix length per VLAN subnet"
}

variable "vlan_start_id" {
  type        = number
  default     = 10
  description = "Starting VLAN ID for the first subnet"
}

variable "vlan_end_id" {
  type        = number
  default     = 100
  description = "Ending VLAN ID for the last subnet"
}

variable "vlan_names" {
  type = map(string)
  default = {
    10  = "mgmt"
    20  = "k8s"
    30  = "proxmox"
    40  = "windows"
    50  = "guest"
    60  = "lb"
    100 = "iot"
  }
  description = "VLAN ID to name mappings"
}

# variable mikrotik_asn {
#   type = string
#   default = "65001"
#   description = "ASN for MikroTik BGP instance"
# }

# variable cilium_asn {
#   type = string
#   default = "65000"
#   description = "ASN for Cilium BGP instance"
# }

# variable mikrotik_router_id {
#   type = string
#   default = "10.42.0.1"
#   description = "Router ID for MikroTik BGP instance"
# }

locals {
  # Homelab CIDR
  homelab_cidr = "${var.vlan_base_network}/16"

  # Generate VLAN IDs from start to end (increment by 1)
  vlan_ids = range(var.vlan_start_id, var.vlan_end_id + 1)

  # Filter VLANs with names defined (for resources that use vlan_names)
  vlan_names_filtered = { for k, v in var.vlan_names : k => v if v != "" }

  # Derive subnet CIDR for each VLAN (third octet = VLAN ID)
  vlan_cidrs = { for id, name in local.vlan_names_filtered : id => cidrsubnet(local.homelab_cidr, 8, tonumber(id)) }

  # Gateway IPs (first usable IP of each subnet)
  vlan_gateways = { for id, name in local.vlan_names_filtered : id => cidrhost(local.vlan_cidrs[id], 1) }

  # Calculate subnet index for /24+ subnets (for DHCP pool)
  subnet_counts = { for id, name in local.vlan_names_filtered : id => id }

  # DHCP pool ranges (100-254 in each subnet)
  vlan_pools = {
    for id, name in local.vlan_names_filtered : id => "${cidrhost(local.vlan_cidrs[id], 100)}-${cidrhost(local.vlan_cidrs[id], 254)}"
  }

  # DNS servers configuration
  dns_servers = {
    primary    = var.upstream_primary_dns
    secondary  = var.upstream_secondary_dns
    management = cidrhost(local.vlan_cidrs[10], 1)
    k8s_guest  = ["1.1.1.1", "9.9.9.9"]
    proxmox    = ["1.1.1.1", "9.9.9.9"]
    other      = ["1.1.1.1", "9.9.9.9"]
  }
}
