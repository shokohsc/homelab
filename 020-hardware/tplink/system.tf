resource "openwrt_system" "system" {
  hostname     = "OpenWrt"
  timezone     = var.system_timezone
  ttylogin     = "0"
  log_size     = "64"
  urandom_seed = "0"
  log_ip       = cidrhost(local.vlan_cidrs["60"], 3)
  log_port     = "601"
  log_proto    = "tcp"
  conloglevel  = "8"
  cronloglevel = "5"
}
