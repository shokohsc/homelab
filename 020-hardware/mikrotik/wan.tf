###########################################################
##  WAN - Dual Internet (fiber primary, mobile failover) ##
##  Static defaults: fiber distance 1, mobile distance 2. ##
###########################################################

# Fiber WAN: DHCP client on ether2 (ONT) for addressing only. The default
# route is static below: a DHCP-installed default never appears when the ISP
# omits option 3 (or the lease was already bound at apply time), leaving all
# traffic on the mobile WAN.
resource "routeros_ip_dhcp_client" "fiber" {
  interface         = "ether2"
  add_default_route = "no"
  use_peer_dns      = false # router DNS stays 1.1.1.1 / 9.9.9.9
  comment           = "WAN-Fiber"
}

resource "routeros_interface_list_member" "wan_fiber" {
  interface = "ether2"
  list      = routeros_interface_list.wan.name
  comment   = "Fiber WAN"
}

# Mobile WAN: DHCP client on ether1 (OPPO CPE) for addressing only. It must
# stay managed here with add_default_route = "no": otherwise it installs a
# distance-1 default that ECMPs against the fiber default and pulls roughly
# half the traffic onto the mobile WAN.
resource "routeros_ip_dhcp_client" "mobile" {
  interface         = "ether1"
  add_default_route = "no"
  use_peer_dns      = true # keep taking DNS from the CPE, as before
  comment           = "WAN-Mobile"
}

# Primary default: wins on distance while the fiber gateway answers pings;
# when it stops answering, the mobile default takes over.
resource "routeros_ip_route" "fiber_default" {
  dst_address   = "0.0.0.0/0"
  gateway       = "192.168.0.1"
  distance      = 1
  check_gateway = "ping"
  comment       = "Fiber ISP"
}

# Failover default: distance 2, so it only carries traffic while the fiber
# gateway is unreachable.
resource "routeros_ip_route" "mobile_default" {
  dst_address   = "0.0.0.0/0"
  gateway       = "192.168.1.1"
  distance      = 2
  check_gateway = "ping"
  comment       = "Mobile ISP"
}
