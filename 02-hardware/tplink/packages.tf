resource "openwrt_opkg" "wanted_packages" {
  packages = ["luasocket", "luci-mod-rpc", "luci-lib-ipkg", "luci-compat"]
}
