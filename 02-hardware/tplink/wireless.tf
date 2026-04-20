resource "openwrt_configfile" "wireless" {
  name    = "wireless"
  content = <<-EOT
config wifi-iface
    option device 'radio0'
    option mode 'ap'
    option ssid 'MGMT'
    option network 'mgmt'
    option encryption 'sae-mixed'
    option key 'strongpassword'

config wifi-iface
    option device 'radio0'
    option mode 'ap'
    option ssid 'GUEST'
    option network 'guest'
    option encryption 'psk2'
    option key 'guestpassword'

config wifi-iface
    option device 'radio0'
    option mode 'ap'
    option ssid 'IOT'
    option network 'iot'
    option encryption 'psk2'
    option key 'iotpassword'
EOT
}
