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
  time_zone_name       = "Europe/Paris"
  time_zone_autodetect = false
}