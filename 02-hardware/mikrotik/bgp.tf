# BGP Instance
resource "routeros_routing_bgp_instance" "cilium" {
  name          = "cilium"
  as            = var.mikrotik_asn
  router_id     = var.mikrotik_router_id
  routing_table = "main"
  vrf           = "main"
}

# BGP Connection - Accept peers from Talos subnet (10.42.20.0/24)
# With listen=true, this accepts any BGP peer from that subnet
resource "routeros_routing_bgp_connection" "cilium" {
  name          = "cilium"
  as            = var.mikrotik_asn
  instance      = routeros_routing_bgp_instance.cilium.name
  routing_table = "main"
  vrf           = "main"
  listen        = true
  connect = false
  local {
    role = var.bgp_local_role
    port = 179
  }
  remote {
    as      = var.cilium_asn
    address = local.vlan_cidrs["20"] # Accept from entire Talos subnet
    port    = 179
  }
  address_families = "ip"
}