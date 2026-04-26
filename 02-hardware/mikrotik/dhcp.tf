###################
## Static Leases ##
###################

locals {
  # Static lease configuration - derive IPs from VLAN subnets
  static_leases = {
    # Management devices (VLAN 10)
    jetkvm = {
      mac  = "30:52:53:00:9E:0A"
      ip   = cidrhost(local.vlan_cidrs["10"], 10)
      vlan = 10
    }
    macbook = {
      mac  = "C8:A3:62:AA:C7:1A"
      ip   = cidrhost(local.vlan_cidrs["10"], 20)
      vlan = 10
    }
    idrac = {
      mac  = "50:9A:4C:68:D9:66"
      ip   = cidrhost(local.vlan_cidrs["10"], 30)
      vlan = 10
    }

    # Kubernetes (VLAN 20)
    k8s_cp1 = {
      mac  = "94:C6:91:A2:82:AD"
      ip   = cidrhost(local.vlan_cidrs["20"], 10)
      vlan = 20
      hostname = "sombra"
    }
    k8s_cp2 = {
      mac  = "1C:69:7A:04:0B:76"
      ip   = cidrhost(local.vlan_cidrs["20"], 20)
      vlan = 20
      hostname = "lucio"
    }
    k8s_cp3 = {
      mac  = "94:C6:91:1C:FF:2E"
      ip   = cidrhost(local.vlan_cidrs["20"], 30)
      vlan = 20
      hostname = "zarya"
    }
    k8s_worker1 = {
      mac  = "1C:69:7A:69:D9:1E"
      ip   = cidrhost(local.vlan_cidrs["20"], 40)
      vlan = 20
      hostname = "mercy"
    }
    k8s_worker2 = {
      mac  = "70:85:C2:5E:D0:D3"
      ip   = cidrhost(local.vlan_cidrs["20"], 50)
      vlan = 20
      hostname = "dva"
    }

    # Proxmox (VLAN 30)
    proxmox1 = {
      mac  = "B8:CA:3A:6C:3D:7C"
      ip   = cidrhost(local.vlan_cidrs["30"], 10)
      vlan = 30
      hostname = "roadhog"
    }
    proxmox2 = {
      mac  = "10:FF:E0:87:D3:5B"
      ip   = cidrhost(local.vlan_cidrs["30"], 20)
      vlan = 30
      hostname = "hanzo"
    }
    proxmox3 = {
      mac  = "10:FF:E0:87:D1:3B"
      ip   = cidrhost(local.vlan_cidrs["30"], 30)
      vlan = 30
      hostname = "genji"
    }

    # Guest (VLAN 60)
    chromecast = {
      mac  = "54:60:09:4A:28:CA"
      ip   = cidrhost(local.vlan_cidrs["60"], 10)
      vlan = 60
    }
    raspberry = {
      mac  = "AA:BB:CC:DD:EE:FF"
      ip   = cidrhost(local.vlan_cidrs["60"], 20)
      vlan = 60
    }

    # IOT (VLAN 100)
    printer = {
      mac  = "C4:65:16:42:3E:0E"
      ip   = cidrhost(local.vlan_cidrs["100"], 10)
      vlan = 100
    }
  }
}

resource "routeros_ip_dhcp_server_lease" "static" {
  for_each = local.static_leases

  address     = each.value.ip
  mac_address = each.value.mac
  server      = "dhcp-vlan${each.value.vlan}"
  comment     = each.key
  # dynamic     = false # (know after apply)
}

############################################
##    Optional: Internal DNS records      ##
############################################

resource "routeros_ip_dns_record" "dhcp_hosts" {
  for_each = local.static_leases

  name    = "${can(each.value.hostname) ? each.value.hostname : each.key}.home.arpa"
  address = each.value.ip
  ttl     = "5m"
  type    = "A"
}
