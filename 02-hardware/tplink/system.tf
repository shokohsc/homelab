resource "openwrt_system" "system" {
  hostname     = "OpenWrt"
  timezone     = var.system_timezone
  ttylogin     = "0"
  log_size     = "64"
  urandom_seed = "0"
}