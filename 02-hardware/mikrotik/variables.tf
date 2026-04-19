variable terraform_state_path {
  type        = string
  default     = "./mikrotik.tfstate"
  description = "Terraform state path"
}

variable routeros_protocol {
  type        = string
  default     = "https"
  description = "Mikrotik router protocol"
}

variable routeros_host {
  type        = string
  default     = "example.com"
  description = "Mikrotik router host"
}

variable routeros_username {
  type        = string
  default     = "opentofu"
  description = "Mikrotik router account username"
}

variable routeros_password {
  type        = string
  default     = "opentofu"
  description = "Mikrotik router account password"
}

variable routeros_insecure {
  type        = bool
  default     = false
  description = "Mikrotik router insecure TLS"
}

variable homelab_cidr {
  type        = string
  default     = "10.42.0.0/16"
  description = "Homelab network CIDR"
}

variable upstream_primary_dns {
  type        = string
  default     = "1.1.1.1"
  description = "Primary upstream DNS server"
}

variable upstream_secondary_dns {
  type        = string
  default     = "9.9.9.9"
  description = "Secondary upstream DNS server"
}
