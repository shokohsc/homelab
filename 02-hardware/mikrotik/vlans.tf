############################################
##                 Bridge                 ##
############################################

import {
  to = routeros_interface_bridge.bridge
  id = "*1D"
}

resource "routeros_interface_bridge" "bridge" {
  name           = "bridge"
  vlan_filtering = var.vlan_filtering # Controls VLAN enforcement
  comment        = "defconf"
  # arp            = "reply-only"
}

############################################
##              Bridge Ports              ##
##         Access ports (untagged)        ##
############################################

# Management (MacBook via powerline)
import {
  to = routeros_interface_bridge_port.eth3
  id = "*2"
}
resource "routeros_interface_bridge_port" "eth3" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether3"
  pvid      = 10
  comment   = "Management (MacBook via powerline)"
}

# OpenWRT AP (trunk)
import {
  to = routeros_interface_bridge_port.eth5
  id = "*4"
}
resource "routeros_interface_bridge_port" "eth5" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether5"
  comment   = "OpenWRT AP (trunk)"
}

# Raspberry Pi (guest)
import {
  to = routeros_interface_bridge_port.eth7
  id = "*6"
}
resource "routeros_interface_bridge_port" "eth7" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether7"
  pvid      = 50
  comment   = "Raspberry Pi (guest)"
}

# Kubernetes nodes
import {
  for_each = {
    "ether8"       = { id = "*7", name = "k8s_ports" }
    "ether9"       = { id = "*8", name = "k8s_ports" }
    "ether11"      = { id = "*A", name = "k8s_ports" }
    "ether13"      = { id = "*C", name = "k8s_ports" }
    "ether23"      = { id = "*16", name = "k8s_ports" }
    "sfp-sfpplus4" = { id = "*1B" }
  }
  to = routeros_interface_bridge_port.k8s_ports[each.key]
  id = each.value.id
}
resource "routeros_interface_bridge_port" "k8s_ports" {
  for_each = toset([
    "ether8", "ether9", "ether11", "ether13", "ether23", "sfp-sfpplus4"
  ])
  bridge    = routeros_interface_bridge.bridge.name
  interface = each.key
  pvid      = 20
  comment   = "Kubernetes nodes"
}

# Proxmox VM access
import {
  for_each = {
    "ether19" = { id = "*12", name = "proxmox_ports" }
    "ether21" = { id = "*14", name = "proxmox_ports" }
    "ether22" = { id = "*15", name = "proxmox_ports" }
  }
  to = routeros_interface_bridge_port.proxmox_ports[each.key]
  id = each.value.id
}
resource "routeros_interface_bridge_port" "proxmox_ports" {
  for_each = toset([
    "ether19", "ether21", "ether22"
  ])
  bridge    = routeros_interface_bridge.bridge.name
  interface = each.key
  pvid      = 30
  comment   = "Proxmox VM access"
}

# JetKVM + iDRAC (Management)
import {
  for_each = {
    "ether15" = { id = "*E", name = "mgmt_ports" }
    "ether17" = { id = "*10", name = "mgmt_ports" }
  }
  to = routeros_interface_bridge_port.mgmt_ports[each.key]
  id = each.value.id
}
resource "routeros_interface_bridge_port" "mgmt_ports" {
  for_each = toset([
    "ether15", "ether17"
  ])
  bridge    = routeros_interface_bridge.bridge.name
  interface = each.key
  pvid      = 10
  comment   = "JetKVM + iDRAC (Management)"
}

# SFP Proxmox admin (tagged trunk)
import {
  for_each = {
    "sfp-sfpplus1" = { id = "*18", name = "sfp_admin" }
    "sfp-sfpplus2" = { id = "*19", name = "sfp_admin" }
    "sfp-sfpplus3" = { id = "*1A", name = "sfp_admin" }
  }
  to = routeros_interface_bridge_port.sfp_admin[each.key]
  id = each.value.id
}
resource "routeros_interface_bridge_port" "sfp_admin" {
  for_each = toset([
    "sfp-sfpplus1", "sfp-sfpplus2", "sfp-sfpplus3"
  ])
  bridge    = routeros_interface_bridge.bridge.name
  interface = each.key
  comment   = "SFP Proxmox admin (tagged trunk)"
}

############################################
##          Bridge VLAN Filtering         ##
############################################

resource "routeros_interface_bridge_vlan" "vlans" {
  for_each = var.vlan_names

  bridge   = routeros_interface_bridge.bridge.name
  vlan_ids = [each.key]
  comment  = each.value

  tagged = [
    "bridge",
    "ether5",       # AP trunk
    "sfp-sfpplus1", # Proxmox
    "sfp-sfpplus2", # Proxmox
    "sfp-sfpplus3"  # Proxmox
  ]

  untagged = lookup({
    10  = ["ether3", "ether15", "ether17"]                                      # Mgmt
    20  = ["ether8", "ether9", "ether11", "ether13", "ether23", "sfp-sfpplus4"] # K8s
    30  = ["ether19", "ether21", "ether22"]                                     # Proxmox
    40  = []                                                                    # VMs
    50  = ["ether7"]                                                            # Guest
    60  = []                                                                    # LB
    100 = []                                                                    # IoT
  }, each.key, [])
}

############################################
##      VLAN Interfaces (L3 gateways)     ##
############################################

resource "routeros_interface_vlan" "vlan_if" {
  for_each = var.vlan_names

  name      = "vlan${each.key}"
  interface = routeros_interface_bridge.bridge.name
  vlan_id   = each.key
  comment   = each.value
}

############################################
##             IP Addressing              ##
############################################

resource "routeros_ip_address" "gateway_ips" {
  for_each = local.vlan_names_filtered

  address   = "${cidrhost(local.vlan_cidrs[each.key], 1)}/${var.vlan_prefix_length}"
  interface = routeros_interface_vlan.vlan_if[each.key].name
  comment   = each.value
}

############################################
##             Address Pools              ##
############################################

resource "routeros_ip_pool" "pools" {
  for_each = local.vlan_names_filtered

  name    = "pool-vlan${each.key}"
  ranges  = [local.vlan_pools[each.key]]
  comment = each.value
}

##############################################
##             DHCP Servers               ##
##############################################

resource "routeros_ip_dhcp_server" "dhcp" {
  for_each = routeros_interface_vlan.vlan_if

  name                      = "dhcp-vlan${each.key}"
  interface                 = each.value.name
  address_pool              = routeros_ip_pool.pools[each.key].name
  lease_time                = "1d"
  dynamic_lease_identifiers = "client-mac"
  disabled                  = false
  comment                   = each.value.comment
}

############################################
## DHCP Networks (Gateway + DNS)          ##
################################################

resource "routeros_ip_dhcp_server_network" "networks" {
  for_each = local.vlan_names_filtered

  address    = local.vlan_cidrs[each.key]
  gateway    = cidrhost(local.vlan_cidrs[each.key], 1)
  dns_server = [var.upstream_primary_dns, var.upstream_secondary_dns]
  comment    = each.value
}

############################################
##              Upstream DNS              ##
############################################

resource "routeros_ip_dns" "dns" {
  allow_remote_requests = true
  servers               = [var.upstream_primary_dns, var.upstream_secondary_dns]
  cache_size            = 2048
}