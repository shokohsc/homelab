###########################################################
##  WAN - Dual Internet (fiber primary, mobile failover) ##
##  Fiber: DHCP-installed default (distance 1).          ##
##  Mobile: recursive static default (distance 2) failover.##
###########################################################

# Fiber WAN: DHCP client on ether2 (ONT). The ISP gateway is only known from
# the lease, so the default route is installed by the DHCP client itself
# (distance 1, auto-updated on renew, removed when the lease is lost). This
# avoids the event-script pitfall: dhcp-client scripts only run on lease
# events, so a script that copies the gateway into a static probe route never
# fires when the lease was already bound at apply time - leaving the probe
# inactive and the distance-1 static default silently resolving through the
# mobile WAN (recursive lookup falls through 0.0.0.0/0). Safe to apply before
# the fiber is installed: the client stays unbound, adds no route, and traffic
# keeps flowing via the mobile default.
resource "routeros_ip_dhcp_client" "fiber" {
  interface              = "ether2"
  add_default_route      = "special-classless" # option-3 default + option-121 classless routes
  default_route_distance = 1
  use_peer_dns           = false # router DNS stays 1.1.1.1 / 9.9.9.9
  comment                = "WAN-Fiber"
}

resource "routeros_interface_list_member" "wan_fiber" {
  interface = "ether2"
  list      = routeros_interface_list.wan.name
  comment   = "Fiber WAN"
}

# Probe route: proves real internet reachability through the mobile WAN's
# gateway (the CPE is static, so no DHCP script is needed). Its scope/target-
# scope lets the mobile default route resolve recursively.
resource "routeros_ip_route" "mobile_probe" {
  dst_address   = "8.8.8.8/32"
  gateway       = "192.168.1.1" # OPPO 5G CPE
  distance      = 1
  scope         = 10
  target_scope  = 10
  check_gateway = "ping"
  comment       = "WAN-Mobile-Probe"
}

# Failover default: resolves recursively through the mobile probe.
# check-gateway pings the probe IP itself (not the CPE), so failover also
# triggers when the CPE is up but its internet is dead (e.g. dropped mobile
# data session). Distance 2 keeps it behind the fiber DHCP default; when the
# fiber lease is lost, the DHCP-installed default disappears and this route
# takes over automatically.
resource "routeros_ip_route" "mobile_default" {
  dst_address   = "0.0.0.0/0"
  gateway       = "8.8.8.8"
  distance      = 2
  scope         = 11
  target_scope  = 11
  check_gateway = "ping"
  comment       = "WAN-Mobile-Default"
}
