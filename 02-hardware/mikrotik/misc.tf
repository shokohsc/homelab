resource "routeros_ipv6_settings" "disable" {
  disable_ipv6 = "true"
}

import {
  to = routeros_interface_list.wan
  id = "*2000010"
}
resource "routeros_interface_list" "wan" { name = "WAN" }

import {
  to = routeros_interface_list.lan
  id = "*2000011"
}
resource "routeros_interface_list" "lan" { name = "LAN" }

resource "routeros_interface_list_member" "bridge_lan" {
  interface = routeros_interface_bridge.bridge.name
  list      = routeros_interface_list.lan.name
  comment   = "Bridge in LAN"
}

resource "routeros_interface_list_member" "vlan_lan" {
  for_each = var.vlan_names

  interface = routeros_interface_vlan.vlan_if[each.key].name
  list      = routeros_interface_list.lan.name
  comment   = "${each.value} VLAN in LAN"
}

resource "routeros_ip_neighbor_discovery_settings" "lan_discovery" {
  discover_interface_list = routeros_interface_list.lan.name
}
resource "routeros_tool_mac_server" "mac_server" {
  allowed_interface_list = routeros_interface_list.lan.name
}
resource "routeros_tool_mac_server_winbox" "winbox_mac_access" {
  allowed_interface_list = routeros_interface_list.lan.name
}

resource "routeros_system_identity" "identity" { name = "Router" }
resource "routeros_system_clock" "timezone" {
  time_zone_name       = var.system_timezone
  time_zone_autodetect = false
}