variable terraform_state_path {
  type        = string
  default     = "./tplink.tfstate"
  description = "Terraform state path"
}

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

variable openwrt_port {
  type        = number
  default     = 8080
  description = "OpenWRT router port"
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
