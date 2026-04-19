############################################
##         Firewall (Core Logic)          ##
##       Base rules for all VLANs         ##
############################################

resource "routeros_ip_firewall_filter" "fasttrack" {
  chain = "forward"
  connection_state = "established,related"
  action = "fasttrack-connection"
}

resource "routeros_ip_firewall_filter" "established" {
  chain = "forward"
  connection_state = "established,related"
  action = "accept"
}

resource "routeros_ip_firewall_filter" "invalid" {
  chain = "forward"
  connection_state = "invalid"
  action = "drop"
  log = yes
  log_prefix = "invalid_connection"
}

resource "routeros_ip_firewall_filter" "new" {
  chain = "forward"
  connection_state = "new"
  connection_nat_state = "!dstnat"
  in_interface = ether1
  action = "drop"
  log = yes
  log_prefix = "new_connection"
}

############################################
##          Block IoT → Internet          ##
############################################

resource "routeros_ip_firewall_filter" "iot_no_internet" {
  chain = "forward"
  src_address = "10.42.100.0/24"
  out_interface = "ether1"
  action = "drop"
}

############################################
##          Priority enforcement          ##
############################################

locals {
  vlan_subnets = {
    10  = "10.42.0.0/24"
    20  = "10.42.20.0/24"
    30  = "10.42.30.0/24"
    40  = "10.42.40.0/24"
    50  = "10.42.50.0/24"
    60  = "10.42.60.0/24"
    100 = "10.42.100.0/24"
  }
}

# Allow higher → lower
resource "routeros_ip_firewall_filter" "allow_priority" {
  for_each = {
    for src_k, src_v in local.vlan_subnets :
    src_k => {
      src = src_v
      dsts = {
        for dst_k, dst_v in local.vlan_subnets :
        dst_k => dst_v if dst_k > src_k
      }
    }
  }

  chain = "forward"
  src_address = each.value.src
  dst_address = join(",", values(each.value.dsts))
  action = "accept"
}

############################################
##        Default deny (east-west)        ##
############################################

resource "routeros_ip_firewall_filter" "deny_inter_vlan" {
  chain = "forward"
  src_address = "10.42.0.0/16"
  dst_address = "10.42.0.0/16"
  action = "drop"
}

############################################
##         NAT (Internet access).         ##
############################################

resource "routeros_ip_firewall_nat" "masquerade" {
  chain = "srcnat"
  out_interface = "ether1"
  action = "masquerade"
}

############################################
##            DNS Firewall Rules.         ##
############################################

resource "routeros_ip_firewall_filter" "dns_allow_trusted" {
  chain = "input"
  protocol = "udp"
  dst_port = "53"
  src_address = "10.42.0.0/16"
  action = "accept"
}

############################################
##         Block Guest → internal DNS     ##
############################################

resource "routeros_ip_firewall_filter" "guest_dns_block_internal" {
  chain = "forward"
  src_address = "10.42.60.0/24"
  dst_address = "10.42.0.1"
  protocol = "udp"
  dst_port = "53"
  action = "drop"
}

############################################
##      Block IoT → DNS except router     ##
############################################

resource "routeros_ip_firewall_filter" "iot_dns_lockdown" {
  chain = "forward"
  src_address = "10.42.100.0/24"
  dst_address = "!10.42.0.1"
  protocol = "udp"
  dst_port = "53"
  action = "drop"
}

