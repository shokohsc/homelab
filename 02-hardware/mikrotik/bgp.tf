# # BGP Instance
# resource "routeros_routing_bgp_instance" "homelab" {
#     name       = "homelab"
#     as         = var.mikrotik_asn
#     router_id  = var.mikrotik_router_id
# }

# # BGP Template - Enable listen for dynamic peers from Talos subnet
# resource "routeros_routing_bgp_template" "cilium_template" {
#     name               = "cilium-template"
#     as                 = var.mikrotik_asn
#     router_id          = var.mikrotik_router_id
#     routing_table      = "main"
#     # output_redistribute = ["connected", "static"]
#     # output = ["connected", "static"]
#     # listen             = true
#     address_families   = "ip"
# }

# # BGP Connection - Accept peers from Talos subnet (10.42.20.0/24)
# # With listen=true, this accepts any BGP peer from that subnet
# resource "routeros_routing_bgp_connection" "talos_peers" {
#     name            = "talos-bgp-peers"
#     as              = var.cilium_asn
#     # remote_address  = local.vlan_cidrs["20"]  # Accept from entire Talos subnet
#     # remote_as       = 65000            # Cilium ASN
#     # local_role      = "ebgp"
#     instance        = routeros_routing_bgp_instance.homelab.name
#     templates       = [routeros_routing_bgp_template.cilium_template.name]
#     routing_table   = "main"
#     hold_time       = "90s"
#     keepalive_time  = "30s"
#     disabled        = false
# }