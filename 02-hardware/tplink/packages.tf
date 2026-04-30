# resource "openwrt_opkg" "wanted_packages" {
#   packages = ["luci", "luci-ssl", "luasocket", "luci-mod-rpc", "luci-lib-ipkg", "luci-compat"] # These packages need to be installed manually beforehand to use this provider
# }

resource "openwrt_opkg" "ap_mode_packages" {
    packages = ["ath10k-firmware-qca988x", "bridge", "kmod-ath10k", "wpad-basic"]
}

resource "openwrt_opkg" "vlan_packages" {
    packages = ["swconfig"]
}
