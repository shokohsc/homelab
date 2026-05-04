resource "openwrt_configfile" "network" {
  name       = "network"
  content    = <<-EOT
config interface 'loopback'
        option device 'lo'
        option proto 'static'
        option ipaddr '127.0.0.1'
        option netmask '255.0.0.0'

config globals 'globals'
        option ula_prefix 'fd97:874c:82ce::/48'

config device
        option name 'br-mgmt'
        option type 'bridge'
        list ports 'eth0.10'

config device
        option name 'br-guest'
        option type 'bridge'
        list ports 'eth0.50'

config device
        option name 'br-iot'
        option type 'bridge'
        list ports 'eth0.100'

config interface 'mgmt'
        option device 'br-mgmt'
        option proto 'static'
        option ipaddr '${cidrhost(local.vlan_cidrs["10"], 2)}'
        option netmask '255.255.255.0'
        option gateway '${cidrhost(local.vlan_cidrs["10"], 1)}'
        option dns '${cidrhost(local.vlan_cidrs["10"], 1)}'

config interface 'guest'
        option device 'br-guest'
        option proto 'none'

config interface 'iot'
        option device 'br-iot'
        option proto 'none'

config switch
        option name 'switch0'
        option reset '1'
        option enable_vlan '1'

config switch_vlan
        option device 'switch0'
        option vlan '10'
        option ports '0t 1t'
        option vid '10'

config switch_vlan
        option device 'switch0'
        option vlan '50'
        option ports '0t 1t'
        option vid '50'

config switch_vlan
        option device 'switch0'
        option vlan '100'
        option ports '0t 1t'
        option vid '100'
EOT
  depends_on = [openwrt_opkg.ap_mode_packages, openwrt_opkg.vlan_packages]
}
