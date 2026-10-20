###########################################################
##  WAN - Dual Internet (fiber primary, mobile failover) ##
##  Both WANs are processed as one logical gateway:      ##
##  recursive default routes with real-internet probes.   ##
###########################################################

# Fiber WAN: DHCP client on ether2 (ONT). Default routes are not taken from
# DHCP; they are managed as recursive static routes below so both WANs behave
# as a single gateway with failover. Safe to apply before the fiber is
# installed: the client stays unbound and traffic keeps flowing via mobile.
resource "routeros_ip_dhcp_client" "fiber" {
  interface         = "ether2"
  add_default_route = "no"  # static recursive defaults instead
  use_peer_dns      = false # router DNS stays 1.1.1.1 / 9.9.9.9
  comment           = "WAN-Fiber"
  # On lease bind, point the fiber probe route at the ISP-provided gateway.
  script = <<-EOT
    :if ([/ip dhcp-client get [find interface="ether2"] status] = "bound") do={
      :local gw [/ip dhcp-client get [find interface="ether2"] gateway]
      /route set [find comment="WAN-Fiber-Probe"] gateway=$gw
    }
  EOT
}

resource "routeros_interface_list_member" "wan_fiber" {
  interface = "ether2"
  list      = routeros_interface_list.wan.name
  comment   = "Fiber WAN"
}

# Probe routes: prove real internet reachability through each WAN's gateway.
# Their scope/target-scope lets the default routes resolve recursively.
resource "routeros_ip_route" "fiber_probe" {
  dst_address   = "1.1.1.1/32"
  gateway       = "192.168.0.1" # placeholder until the fiber DHCP lease binds
  distance      = 1
  scope         = 10
  target_scope  = 10
  check_gateway = "ping"
  comment       = "WAN-Fiber-Probe"
  lifecycle {
    ignore_changes = [gateway] # rewritten by the dhcp-client script on renew
  }
}

resource "routeros_ip_route" "mobile_probe" {
  dst_address   = "8.8.8.8/32"
  gateway       = "192.168.1.1" # OPPO 5G CPE
  distance      = 1
  scope         = 10
  target_scope  = 10
  check_gateway = "ping"
  comment       = "WAN-Mobile-Probe"
}

# Single logical default gateway, resolved recursively through the probe IPs.
# check-gateway pings the probe IP itself (not the CPE), so failover also
# triggers when a CPE is up but its internet is dead (e.g. dropped mobile
# data session). Fiber wins with distance 1 while healthy.
resource "routeros_ip_route" "fiber_default" {
  dst_address   = "0.0.0.0/0"
  gateway       = "1.1.1.1"
  distance      = 1
  scope         = 11
  target_scope  = 11
  check_gateway = "ping"
  comment       = "WAN-Fiber-Default"
}

resource "routeros_ip_route" "mobile_default" {
  dst_address   = "0.0.0.0/0"
  gateway       = "8.8.8.8"
  distance      = 2
  scope         = 11
  target_scope  = 11
  check_gateway = "ping"
  comment       = "WAN-Mobile-Default"
}
