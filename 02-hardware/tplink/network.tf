resource "openwrt_configfile" "network" {
  name    = "network"
  content = <<-EOT
config device
    option name 'br-lan'
    option type 'bridge'
    list ports 'eth0'

# VLAN filtering
config bridge-vlan
    option device 'br-lan'
    option vlan '10'
    list ports 'eth0:t'

config bridge-vlan
    option device 'br-lan'
    option vlan '60'
    list ports 'eth0:t'

config bridge-vlan
    option device 'br-lan'
    option vlan '100'
    list ports 'eth0:t'

# Interfaces
config interface 'mgmt'
    option device 'br-lan.10'
    option proto 'dhcp'

config interface 'guest'
    option device 'br-lan.60'
    option proto 'dhcp'

config interface 'iot'
    option device 'br-lan.100'
    option proto 'dhcp'
EOT
}
