############################################
##             Provider Config            ##
############################################

terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
    }
  }
  required_version = ">= 1.5.0"
}

provider "routeros" {
  hosturl  = "${var.routeros_protocol}://${var.routeros_host}"
  username = var.routeros_username
  password = var.routeros_password
  insecure = var.routeros_insecure
}