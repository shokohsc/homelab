###################
## Static Leases ##
###################

locals {
  static_leases = {
    # Management devices
    jetkvm = {
      mac = "30:52:53:00:9E:0A"
      ip  = "10.42.0.10"
      vlan = 10
    }
    macbook = {
      mac = "C8:A3:62:AA:C7:1A"
      ip  = "10.42.0.20"
      vlan = 10
    }
    idrac = {
      mac = "50:9A:4C:68:D9:66"
      ip  = "10.42.0.30"
      vlan = 10
    }

    # Kubernetes
    k8s_cp1 = {
      mac = "94:C6:91:A2:82:AD"
      ip  = "10.42.20.10"
      vlan = 20
    }
    k8s_cp2 = {
      mac = "1C:69:7A:04:0B:76"
      ip  = "10.42.20.20"
      vlan = 20
    }
    k8s_cp3 = {
      mac = "94:C6:91:1C:FF:2E"
      ip  = "10.42.20.30"
      vlan = 20
    }
    k8s_worker1 = {
      mac = "1C:69:7A:69:D9:1E"
      ip  = "10.42.20.40"
      vlan = 20
    }
    k8s_worker2 = {
      mac = "70:85:C2:5E:D0:D3"
      ip  = "10.42.20.50"
      vlan = 20
    }

    # Proxmox
    proxmox1 = {
      mac = "B8:CA:3A:6C:3D:78"
      ip  = "10.42.30.10"
      vlan = 30
    }
    proxmox2 = {
      mac = ""
      ip  = "10.42.30.20"
      vlan = 30
    }
    proxmox3 = {
      mac = ""
      ip  = "10.42.30.30"
      vlan = 30
    }
  }
}

resource "routeros_ip_dhcp_server_lease" "static" {
  for_each = local.static_leases

  address     = each.value.ip
  mac_address = each.value.mac
  server      = "dhcp-vlan${each.value.vlan}"
  comment     = each.key
  dynamic     = false
}

############################################
##    Optional: Internal DNS records      ##
############################################

resource "routeros_ip_dns_record" "dhcp_hosts" {
  for_each = local.static_leases

  name    = "${each.key}.home"
  address = each.value.ip
  ttl     = "5m"
}
