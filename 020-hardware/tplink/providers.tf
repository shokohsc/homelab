############################################
##             Provider Config            ##
############################################

locals {
  openwrt_remote = "${var.openwrt_protocol}://${var.openwrt_host}"
}

terraform {
  required_providers {
    openwrt = {
      source = "foxboron/openwrt"
    }
  }
  required_version = ">= 1.5.0"
}

provider "openwrt" {
  user         = var.openwrt_username
  password     = var.openwrt_password
  remote       = local.openwrt_remote
  api_timeouts = var.openwrt_api_timeouts
}
