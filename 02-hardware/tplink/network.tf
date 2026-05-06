# Switch ports
# CPU: 0
# WAN: 1
# LAN_1: 2
# LAN_2: 3
# LAN_3: 4
# LAN_4: 5
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
        option multicast '1'
        option igmp_snooping '1'

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
        option vid '10'
        option ports '0t 1t 2t 3'

config switch_vlan
        option device 'switch0'
        option vlan '50'
        option vid '50'
        option ports '0t 1t 2t 4'

config switch_vlan
        option device 'switch0'
        option vlan '100'
        option vid '100'
        option ports '0t 1t 2t 5'

config device
        option name 'eth0'

config device
        option name 'eth0.10'
        option type '8021q'
        option ifname 'eth0'
        option vid '10'

config device
        option name 'eth0.50'
        option type '8021q'
        option ifname 'eth0'
        option vid '50'
        option multicast '1'

config device
        option name 'eth0.100'
        option type '8021q'
        option ifname 'eth0'
        option vid '100'

config device
        option name 'wlan0'

config device
        option name 'wlan0-1'
        option multicast '1'

config device
        option name 'wlan0-2'

config device
        option name 'wlan1'

config device
        option name 'wlan1-1'
        option multicast '1'

config device
        option name 'wlan1-2'
EOT
  depends_on = [openwrt_opkg.ap_mode_packages, openwrt_opkg.vlan_packages]
}
