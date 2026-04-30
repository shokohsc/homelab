resource "openwrt_service" "dnsmasq" {
    name    = "dnsmasq"
    enabled = false
}

resource "openwrt_service" "firewall" {
    name    = "firewall"
    enabled = false
}