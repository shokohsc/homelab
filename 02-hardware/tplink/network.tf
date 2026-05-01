resource "openwrt_configfile" "network" {
    name    = "network"
    content = <<-EOT
config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config interface 'wan'
    option ifname 'eth1'
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

config interface 'lan_mgmt'
    option ifname 'eth0.10'
    option type 'bridge'
    option proto 'static'
    option ipaddr '${cidrhost(local.vlan_cidrs["10"], 2)}'
    option netmask '255.255.255.0'
    option gateway '${cidrhost(local.vlan_cidrs["10"], 1)}'
    option dns '${cidrhost(local.vlan_cidrs["10"], 1)}'

config interface 'lan_guest'
    option ifname 'eth0.50'
    option type 'bridge'
    option proto 'static'
    option ipaddr '${cidrhost(local.vlan_cidrs["50"], 2)}'
    option netmask '255.255.255.0'

config interface 'lan_iot'
    option ifname 'eth0.100'
    option type 'bridge'
    option proto 'static'
    option ipaddr '${cidrhost(local.vlan_cidrs["100"], 2)}'
    option netmask '255.255.255.0'
EOT
    depends_on = [openwrt_opkg.ap_mode_packages, openwrt_opkg.vlan_packages]
}
