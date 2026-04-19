############################################
##                 Bridge                 ##
############################################

resource "routeros_interface_bridge" "br0" {
  name           = "br0"
  vlan_filtering = true
#  arp            = "reply-only"
}

############################################
##              Bridge Ports              ##
##         Access ports (untagged)        ##
############################################


# Management (MacBook via powerline)
resource "routeros_interface_bridge_port" "eth3" {
  bridge = routeros_interface_bridge.br0.name
  interface = "ether3"
  pvid = 10
}

# OpenWRT AP (trunk)
resource "routeros_interface_bridge_port" "eth5" {
  bridge = routeros_interface_bridge.br0.name
  interface = "ether5"
}

# Raspberry Pi (mgmt)
resource "routeros_interface_bridge_port" "eth7" {
  bridge = routeros_interface_bridge.br0.name
  interface = "ether7"
  pvid = 10
}

# Kubernetes nodes
resource "routeros_interface_bridge_port" "k8s_ports" {
  for_each = toset([
    "ether8","ether9","ether11","ether13","ether23","sfp-sfpplus4"
  ])
  bridge    = routeros_interface_bridge.br0.name
  interface = each.key
  pvid      = 20
}

# Proxmox VM access
resource "routeros_interface_bridge_port" "proxmox_ports" {
  for_each = toset([
    "ether19","ether21","ether22"
  ])
  bridge    = routeros_interface_bridge.br0.name
  interface = each.key
  pvid      = 30
}

# iDRAC + JetKVM (IoT)
resource "routeros_interface_bridge_port" "iot_ports" {
  for_each = toset([
    "ether15","ether17"
  ])
  bridge    = routeros_interface_bridge.br0.name
  interface = each.key
  pvid      = 100
}

# SFP Proxmox admin (tagged trunk)
resource "routeros_interface_bridge_port" "sfp_admin" {
  for_each = toset([
    "sfp-sfpplus1","sfp-sfpplus2","sfp-sfpplus3"
  ])
  bridge    = routeros_interface_bridge.br0.name
  interface = each.key
}

############################################
##             VLAN Definitions           ##
############################################

locals {
  vlans = {
    10  = "mgmt"
    20  = "k8s"
    30  = "proxmox"
    40  = "lb"
    50  = "windows"
    60  = "guest"
    100 = "iot"
  }
}

############################################
##          Bridge VLAN Filtering         ##
############################################

resource "routeros_interface_bridge_vlan" "vlans" {
  for_each = local.vlans

  bridge  = routeros_interface_bridge.br0.name
  vlan_ids = [each.key]

  tagged = [
    "br0",
    "ether5", # AP trunk
    "sfp-sfpplus1",
    "sfp-sfpplus2",
    "sfp-sfpplus3",
    "sfp-sfpplus4"
  ]

  untagged = lookup({
    10  = ["ether3","ether7"]
    20  = ["ether8","ether9","ether11","ether13","ether23"]
    30  = ["ether19","ether21","ether22"]
    100 = ["ether15","ether17"]
  }, each.key, [])
}

############################################
##      VLAN Interfaces (L3 gateways)     ##
############################################

resource "routeros_interface_vlan" "vlan_if" {
  for_each = local.vlans

  name      = "vlan${each.key}"
  interface = routeros_interface_bridge.br0.name
  vlan_id   = each.key
}

############################################
##             IP Addressing              ##
############################################

resource "routeros_ip_address" "gateway_ips" {
  for_each = {
    10  = "10.42.0.1/24"
    20  = "10.42.20.1/24"
    30  = "10.42.30.1/24"
    40  = "10.42.40.1/24"
    50  = "10.42.50.1/24"
    60  = "10.42.60.1/24"
    100 = "10.42.100.1/24"
  }

  address   = each.value
  interface = routeros_interface_vlan.vlan_if[each.key].name
}

############################################
##             Address Pools              ##
############################################

resource "routeros_ip_pool" "pools" {
  for_each = {
    10  = "10.42.0.100-10.42.0.254"
    20  = "10.42.20.100-10.42.20.254"
    30  = "10.42.30.100-10.42.30.254"
    40  = "10.42.40.100-10.42.40.254"
    50  = "10.42.50.100-10.42.50.254"
    60  = "10.42.60.100-10.42.60.254"
    100 = "10.42.100.100-10.42.100.254"
  }

  name   = "pool-vlan${each.key}"
  ranges = [each.value]
}

############################################
##             DHCP Servers               ##
############################################

resource "routeros_ip_dhcp_server" "dhcp" {
  for_each = routeros_interface_vlan.vlan_if

  name         = "dhcp-vlan${each.key}"
  interface    = each.value.name
  address_pool = routeros_ip_pool.pools[each.key].name
  lease_time   = "1d"
  disabled     = false
}

################################################
## Optional: Block unknown devices (per VLAN) ##
################################################

resource "routeros_ip_dhcp_server" "secure_dhcp" {
  for_each = routeros_ip_dhcp_server.dhcp

  name            = each.value.name
  interface       = each.value.interface
  address_pool    = each.value.address_pool
  lease_time      = each.value.lease_time
  authoritative   = "yes"
  add_arp         = true
}

############################################
##     DHCP Networks (Gateway + DNS)      ##
############################################

resource "routeros_ip_dhcp_server_network" "networks" {
  for_each = {
    10 = { subnet = "10.42.0.0/24", dns = ["10.42.0.1"] }
    20 = { subnet = "10.42.20.0/24", dns = ["10.42.0.1"] }
    30 = { subnet = "10.42.30.0/24", dns = ["10.42.0.1"] }
    40 = { subnet = "10.42.40.0/24", dns = ["10.42.0.1"] }
    50 = { subnet = "10.42.50.0/24", dns = ["1.1.1.1","9.9.9.9"] }
    60 = { subnet = "10.42.60.0/24", dns = ["1.1.1.1"] }
    100 = { subnet = "10.42.100.0/24", dns = ["10.42.0.1"] }
  }

  address    = each.value.subnet
  gateway    = replace(each.value.subnet, "0/24", "1")
  dns_server = each.value.dns
}

############################################
##              Upstream DNS              ##
############################################

resource "routeros_ip_dns" "dns" {
  allow_remote_requests = true
  servers               = ["1.1.1.1", "9.9.9.9"]
  cache_size            = 2048
}
