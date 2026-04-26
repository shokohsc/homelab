############################################
##  Read existing firewall rules (for ordering)##
############################################

data "routeros_ip_firewall" "existing" {
  rules {}
}

############################################
##       Input Chain - Management Access   ##
##     Critical: must exist before enabling vlan_filtering
############################################

# Allow established connections to router
resource "routeros_ip_firewall_filter" "input_established" {
  chain        = "input"
  action       = "accept"
  connection_state = "established,related"
  comment      = "Rule 00 - Allow established,related connections"
}

# Allow ICMP (ping)
resource "routeros_ip_firewall_filter" "input_icmp" {
  chain        = "input"
  action       = "accept"
  protocol     = "icmp"
  comment      = "Rule 00 - Allow icmp connections"
}

# Allow management access from mgmt VLAN only
resource "routeros_ip_firewall_filter" "input_mgmt" {
  chain        = "input"
  action       = "accept"
  src_address  = local.vlan_cidrs["10"]
  comment      = "Rule 00 - Allow management from VLAN 10"
}

# Drop everything else on input chain
resource "routeros_ip_firewall_filter" "input_default_deny" {
  chain  = "input"
  action = "drop"
  comment      = "Rule 00 - Drop everything else"
}

############################################
##       Forward Chain - Core Rules       ##
##   Ordered via place_before chaining    ##
############################################

# Rule 1: Fasttrack (lowest priority, created first)
resource "routeros_ip_firewall_filter" "fasttrack" {
  chain           = "forward"
  action          = "fasttrack-connection"
  connection_state = "established,related"
  comment         = "Rule 01-Fasttrack"
}

# Rule 2: Accept established/related - placed before fasttrack
resource "routeros_ip_firewall_filter" "established" {
  chain           = "forward"
  action          = "accept"
  connection_state = "established,related"
  place_before    = routeros_ip_firewall_filter.fasttrack.id
  comment         = "Rule 02-Accept-Established"
}

# Rule 3: Drop invalid - placed before established
resource "routeros_ip_firewall_filter" "invalid" {
  chain           = "forward"
  action          = "drop"
  connection_state = "invalid"
  log             = true
  log_prefix      = "invalid_connection"
  place_before    = routeros_ip_firewall_filter.established.id
  comment         = "Rule 03-Drop-Invalid"
}

# Rule 4: Drop new from WAN - placed before invalid
resource "routeros_ip_firewall_filter" "new_wan" {
  chain                = "forward"
  action               = "drop"
  connection_state      = "new"
  connection_nat_state  = "!dstnat"
  in_interface         = "ether1"
  log                  = true
  log_prefix           = "new_connection"
  place_before         = routeros_ip_firewall_filter.invalid.id
  comment              = "Rule 04-Drop-New-From-WAN"
}

############################################
##      Block IoT → Internet             ##
##   Placed after core rules             ##
############################################

resource "routeros_ip_firewall_filter" "iot_no_internet" {
  chain         = "forward"
  action        = "drop"
  src_address   = local.vlan_cidrs["100"]
  out_interface = "ether1"
  place_before  = routeros_ip_firewall_filter.new_wan.id
  comment       = "Rule 05-Block-IoT-Internet"
}

############################################
##      Allow higher → lower VLANs       ##
############################################

resource "routeros_ip_firewall_filter" "allow_priority" {
  for_each = {
    for src_k, _ in local.vlan_names_filtered :
    src_k => {
      src = local.vlan_cidrs[src_k]
      dsts = {
        for dst_k, _ in local.vlan_names_filtered :
        dst_k => local.vlan_cidrs[dst_k] if dst_k < src_k
      }
    }
  }

  chain        = "forward"
  action       = "accept"
  src_address  = each.value.src
  dst_address  = join(",", values(each.value.dsts))
  place_before = routeros_ip_firewall_filter.iot_no_internet.id
  comment      = "Rule 06-Allow-Priority-${each.key}"
}

############################################
##      Default deny (east-west)          ##
##   Last rule before specific blocks     ##
############################################

resource "routeros_ip_firewall_filter" "deny_inter_vlan" {
  chain        = "forward"
  action       = "drop"
  src_address  = var.homelab_cidr
  dst_address  = var.homelab_cidr
  # Place before first allow_priority rule (k8s with priority 20)
  place_before = routeros_ip_firewall_filter.allow_priority["20"].id
  comment      = "Rule 07-Deny-InterVLAN"
}

############################################
##         Block Guest → DNS              ##
############################################

resource "routeros_ip_firewall_filter" "guest_dns_block" {
  chain       = "forward"
  action      = "drop"
  src_address = local.vlan_cidrs["60"]
  dst_address = cidrhost(local.vlan_cidrs["10"], 1)
  protocol    = "udp"
  dst_port    = "53"
  place_before = routeros_ip_firewall_filter.deny_inter_vlan.id
  comment     = "Rule 08-Block-Guest-DNS"
}

############################################
##      Block IoT → DNS except router    ##
############################################

resource "routeros_ip_firewall_filter" "iot_dns_lockdown" {
  chain       = "forward"
  action      = "drop"
  src_address = local.vlan_cidrs["100"]
  dst_address = cidrhost(local.vlan_cidrs["10"], 1)
  protocol    = "udp"
  dst_port    = "53"
  place_before = routeros_ip_firewall_filter.guest_dns_block.id
  comment     = "Rule 09-Block-IoT-DNS"
}

############################################
##            DNS Allow Trusted          ##
##     Allow DNS from internal subnets   ##
############################################

resource "routeros_ip_firewall_filter" "dns_allow_trusted" {
  chain       = "forward"
  action      = "accept"
  protocol    = "udp"
  dst_port    = "53"
  src_address = var.homelab_cidr
  place_before = routeros_ip_firewall_filter.iot_dns_lockdown.id
  comment     = "Rule 10-Allow-DNS-Trusted"
}

############################################
##         NAT (Internet access)         ##
############################################

import {
  to = routeros_ip_firewall_nat.masquerade
  id = "*1"
}

resource "routeros_ip_firewall_nat" "masquerade" {
  chain        = "srcnat"
  out_interface = "ether1"
  action       = "masquerade"
  comment      = "NAT-Masquerade"
  out_interface_list = routeros_interface_list.wan.name
}