variable openwrt_protocol {
  type        = string
  default     = "https"
  description = "OpenWRT router protocol"
}

variable openwrt_host {
  type        = string
  default     = "example.com"
  description = "OpenWRT router host"
}

variable openwrt_username {
  type        = string
  default     = "opentofu"
  description = "OpenWRT router account username"
}

variable openwrt_password {
  type        = string
  default     = "opentofu"
  description = "OpenWRT router account password"
}

variable wifi_password_ssid_mgmt {
  type       = string
  default     = "mgmt-password"
  description = "OpenWRT router wifi password for SSID MGMT"
}

variable wifi_password_ssid_guest {
  type       = string
  default     = "guest-password"
  description = "OpenWRT router wifi password for SSID Guest"
}

variable wifi_password_ssid_iot {
  type       = string
  default     = "iot-password"
  description = "OpenWRT router wifi password for SSID IoT"
}

variable openwrt_api_timeouts {
  type = object({
    api     = string
    fs      = object({
      read_file = string
      remove_file = string
      write_file = string
    })
    opkg = object({
      check_package = string
      install_packages = string
      remove_packages = string
      update_packages = string
    })
    service = object({
      disable_service = string
      enable_service = string
      is_enabled = string
      list_services = string
      restart_service = string
      start_service = string
      stop_service = string
    })
    uci = object({
      add = string
      commit_or_revert = string
      delete = string
      get_all = string
      t_set = string
    })
  })
  default = {
    api     = "5s",
    fs      = {
      read_file = "10s",
      remove_file = "10s",
      write_file = "10s"
    },
    opkg = {
      check_package = "60s",
      install_packages = "60s",
      remove_packages = "60s",
      update_packages = "60s"
    },
    service = {
      disable_service = "20s",
      enable_service = "20s",
      is_enabled = "20s",
      list_services = "20s",
      restart_service = "20s",
      start_service = "20s",
      stop_service = "20s"
    },
    uci = {
      add = "60s",
      commit_or_revert = "60s",
      delete = "60s",
      get_all = "60s",
      t_set = "60s"
    }
  }
  description = "OpenWRT router account api timeouts"
}

variable vlan_base_network {
  type        = string
  default     = "10.42.0.0"
  description = "Base network for VLAN subnets (e.g., 10.42.0.0 for 10.42.0.0/24, 10.42.1.0/24, etc.)"
}

variable vlan_prefix_length {
  type        = number
  default     = 24
  description = "CIDR prefix length per VLAN subnet"
}

variable vlan_start_id {
  type        = number
  default     = 10
  description = "Starting VLAN ID for the first subnet"
}

variable vlan_end_id {
  type        = number
  default     = 100
  description = "Ending VLAN ID for the last subnet"
}

variable vlan_names {
  type        = map(string)
  default     = {
    10  = "mgmt"
    60  = "guest"
    100 = "iot"
  }
  description = "VLAN ID to name mappings"
}

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
}
