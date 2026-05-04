###########################################################
##            Input Chain - Management Access            ##
##  Critical: must exist before enabling vlan_filtering  ##
###########################################################

resource "routeros_ip_firewall_filter" "accept_established_related_untracked" {
  disabled         = var.disable_firewall_rules
  action           = "accept"
  chain            = "input"
  connection_state = "established,related,untracked"
  comment          = "Rule 000-Accept-Established-Related-Untracked"
  place_before     = routeros_ip_firewall_filter.drop_invalid.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

resource "routeros_ip_firewall_filter" "drop_invalid" {
  disabled         = var.disable_firewall_rules
  action           = "drop"
  chain            = "input"
  connection_state = "invalid"
  log              = true
  log_prefix       = "drop_input_invalid"
  comment          = "Rule 001-Drop-Invalid"
  place_before     = routeros_ip_firewall_filter.accept_icmp.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

resource "routeros_ip_firewall_filter" "accept_icmp" {
  disabled     = var.disable_firewall_rules
  action       = "accept"
  chain        = "input"
  protocol     = "icmp"
  comment      = "Rule 002-Accept-ICMP"
  place_before = routeros_ip_firewall_filter.fasttrack.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

resource "routeros_ip_firewall_filter" "capsman_accept_local_loopback" {
  disabled     = var.disable_firewall_rules
  action       = "accept"
  chain        = "input"
  dst_address  = "127.0.0.1"
  comment      = "Rule 003-Capsman-Accept-Local-Loopback"
  place_before = routeros_ip_firewall_filter.drop_all_not_lan.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

resource "routeros_ip_firewall_filter" "accept_mgmt_default_cidr" {
  disabled     = var.disable_firewall_rules
  action       = "accept"
  chain        = "input"
  src_address  = "${var.vlan_base_network}/24"
  comment      = "Rule 004-Accept-Mgmt-Default-CIDR"
  place_before = routeros_ip_firewall_filter.drop_all_not_lan.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

resource "routeros_ip_firewall_filter" "accept_mgmt_vlan_cidr" {
  disabled     = var.disable_firewall_rules
  action       = "accept"
  chain        = "input"
  src_address  = local.vlan_cidrs["10"]
  comment      = "Rule 005-Accept-Mgmt-VLAN-CIDR"
  place_before = routeros_ip_firewall_filter.accept_mgmt_default_cidr.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

resource "routeros_ip_firewall_filter" "drop_all_not_lan" {
  disabled          = var.disable_firewall_rules
  action            = "drop"
  chain             = "input"
  in_interface_list = "!${routeros_interface_list.lan.name}"
  log               = true
  log_prefix        = "drop_not_lan"
  comment           = "Rule 006-Drop-All-Not-LAN"
  place_before      = routeros_ip_firewall_filter.fasttrack.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

############################################
##       Forward Chain - Core Rules       ##
############################################

# # Critical: Allow BGP forward traffic - must be placed BEFORE fasttrack
# # Note: RouterOS doesn't support rule ordering via TF, place manually or use scripts
# resource "routeros_ip_firewall_filter" "bgp_forward" {
#   disabled = var.disable_firewall_rules
#   chain         = "forward"
#   action        = "accept"
#   comment       = "Rule 007-BGP-Forward Allow BGP traffic for LoadBalancer - place before fasttrack"
#   dst_address   = local.vlan_cidrs["60"] # LoadBalancer cidr gateway
#   protocol      = "tcp"
#   dst_port      = "179"
#   connection_state = "established,related"
#   place_before = routeros_ip_firewall_filter.fasttrack.id
# lifecycle {
#     ignore_changes = [
#       disabled
#     ]  
# }
# }

# Rule 1: Fasttrack (lowest priority, created first)
resource "routeros_ip_firewall_filter" "fasttrack" {
  disabled         = var.disable_firewall_rules
  chain            = "forward"
  action           = "fasttrack-connection"
  connection_state = "established,related"
  comment          = "Rule 010-Fasttrack"
  hw_offload       = true
  place_before     = routeros_ip_firewall_filter.established.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

# Rule 2: Accept established/related - placed before fasttrack
resource "routeros_ip_firewall_filter" "established" {
  disabled         = var.disable_firewall_rules
  chain            = "forward"
  action           = "accept"
  connection_state = "established,related"
  comment          = "Rule 020-Accept-Established"
  place_before     = routeros_ip_firewall_filter.invalid.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

# Rule 3: Drop invalid - placed before established
resource "routeros_ip_firewall_filter" "invalid" {
  disabled         = var.disable_firewall_rules
  chain            = "forward"
  action           = "drop"
  connection_state = "invalid"
  log              = true
  log_prefix       = "invalid_connection"
  comment          = "Rule 030-Drop-Invalid"
  place_before     = routeros_ip_firewall_filter.new_wan.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

# Rule 4: Drop new from WAN - placed before invalid
resource "routeros_ip_firewall_filter" "new_wan" {
  disabled             = var.disable_firewall_rules
  chain                = "forward"
  action               = "drop"
  connection_state     = "new"
  connection_nat_state = "!dstnat"
  in_interface         = "ether1"
  log                  = true
  log_prefix           = "new_connection"
  comment              = "Rule 040-Drop-New-From-WAN"
  place_before         = routeros_ip_firewall_filter.iot_no_internet.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

############################################
##      Block IoT → Internet             ##
##   Placed after core rules             ##
############################################

resource "routeros_ip_firewall_filter" "iot_no_internet" {
  disabled      = var.disable_firewall_rules
  chain         = "forward"
  action        = "drop"
  src_address   = local.vlan_cidrs["100"]
  out_interface = "ether1"
  log           = true
  log_prefix    = "iot_no_internet"
  comment       = "Rule 050-Block-IoT-Internet"
  place_before  = routeros_ip_firewall_filter.allow_bridge_to_vlans.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

resource "routeros_ip_firewall_filter" "allow_bridge_to_vlans" {
  disabled     = var.disable_firewall_rules
  chain        = "forward"
  action       = "accept"
  src_address  = var.homelab_cidr
  dst_address  = var.homelab_cidr
  comment      = "Rule 055-Allow-Bridge-to-VLANs"
  place_before = routeros_ip_firewall_filter.allow_priority["10"].id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

############################################
##      Allow lower → higher VLANs       ##
############################################

resource "routeros_ip_firewall_filter" "allow_priority" {
  for_each = {
    for src_k, _ in local.vlan_names_filtered :
    src_k => {
      src = local.vlan_cidrs[src_k]
      dsts = {
        for dst_k, _ in local.vlan_names_filtered :
        dst_k => local.vlan_cidrs[dst_k] if dst_k > src_k
      }
    }
  }

  disabled         = var.disable_firewall_rules
  chain            = "forward"
  action           = "accept"
  src_address      = each.value.src
  dst_address_list = join(",", values(each.value.dsts))
  comment          = "Rule 060-Allow-Priority-${each.key}"
  place_before     = routeros_ip_firewall_filter.deny_inter_vlan.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

############################################
##      Default deny (east-west)          ##
##   Last rule before specific blocks     ##
############################################

resource "routeros_ip_firewall_filter" "deny_inter_vlan" {
  disabled    = var.disable_firewall_rules
  chain       = "forward"
  action      = "drop"
  src_address = var.homelab_cidr
  dst_address = var.homelab_cidr
  log         = true
  log_prefix  = "deny_inter_vlan"
  # Place before first allow_priority rule (k8s with priority 20)
  comment      = "Rule 070-Deny-InterVLAN"
  place_before = routeros_ip_firewall_filter.guest_dns_block.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

############################################
##         Block Guest → DNS              ##
############################################

resource "routeros_ip_firewall_filter" "guest_dns_block" {
  disabled     = var.disable_firewall_rules
  chain        = "forward"
  action       = "drop"
  src_address  = local.vlan_cidrs["50"]
  dst_address  = cidrhost(local.vlan_cidrs["10"], 1)
  protocol     = "udp"
  dst_port     = "53"
  log          = true
  log_prefix   = "deny_inter_vlan"
  comment      = "Rule 080-Block-Guest-DNS"
  place_before = routeros_ip_firewall_filter.iot_dns_lockdown.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

############################################
##      Block IoT → DNS except router    ##
############################################

resource "routeros_ip_firewall_filter" "iot_dns_lockdown" {
  disabled     = var.disable_firewall_rules
  chain        = "forward"
  action       = "drop"
  src_address  = local.vlan_cidrs["100"]
  dst_address  = cidrhost(local.vlan_cidrs["10"], 1)
  protocol     = "udp"
  dst_port     = "53"
  log          = true
  log_prefix   = "iot_dns_lockdown"
  comment      = "Rule 090-Block-IoT-DNS"
  place_before = routeros_ip_firewall_filter.dns_allow_trusted.id
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

############################################
##            DNS Allow Trusted          ##
##     Allow DNS from internal subnets   ##
############################################

resource "routeros_ip_firewall_filter" "dns_allow_trusted" {
  disabled    = var.disable_firewall_rules
  chain       = "forward"
  action      = "accept"
  protocol    = "udp"
  dst_port    = "53"
  src_address = var.homelab_cidr
  comment     = "Rule 100-Allow-DNS-Trusted"
  lifecycle {
    ignore_changes = [
      disabled
    ]
  }
}

############################################
##         NAT (Internet access)         ##
############################################

resource "routeros_ip_firewall_nat" "masquerade" {
  chain              = "srcnat"
  out_interface      = "ether1"
  action             = "masquerade"
  comment            = "NAT-Masquerade"
  out_interface_list = routeros_interface_list.wan.name
}