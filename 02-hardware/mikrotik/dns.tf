locals {
  # Static lease configuration - derive IPs from VLAN subnets
  homelab_records = {
    # Gateway
    mikrotik = {
      ip       = cidrhost(local.vlan_cidrs["10"], 1)
      hostname = "mikrotik"
    }
    # Access Point
    tplink = {
      ip       = cidrhost(local.vlan_cidrs["10"], 2)
      hostname = "tplink"
    }
    # Talos endpoints
    k8s_1 = {
      ip       = cidrhost(local.vlan_cidrs["20"], 10)
      hostname = "k8s"
    }
    k8s_2 = {
      ip       = cidrhost(local.vlan_cidrs["20"], 20)
      hostname = "k8s"
    }
    k8s_3 = {
      ip       = cidrhost(local.vlan_cidrs["20"], 30)
      hostname = "k8s"
    }
  }
}

###################################
##     Internal DNS records      ##
###################################

resource "routeros_ip_dns_record" "homelab_records" {
  for_each = local.homelab_records

  name    = "${each.value.hostname}.home.arpa"
  address = each.value.ip
  ttl     = "5m"
  type    = "A"
}
