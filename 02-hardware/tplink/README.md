# OpenWrt Access Point Configuration

## Overview

This OpenTofu configuration manages a TP-Link Archer C7 acting as a WiFi access point for the MikroTik network. It configures network interfaces and wireless networks for VLANs.

## Hardware

- **Model**: TP-Link Archer C7 v2
- **Role**: WiFi access point with VLAN passthrough

## VLANs

| VLAN ID | Network | SSID | Purpose |
|--------|---------|------|---------|
| 10 | br-lan.10 | MGMT | Management network |
| 60 | br-lan.60 | GUEST | Guest WiFi |
| 100 | br-lan.100 | IOT | IoT devices |

## Prerequisites

1. OpenTofu (tofu) >= 1.5.0
2. OpenWrt with RPC API enabled
3. Access to OpenWrt device via HTTPS

## Quick Start

```bash
# Initialize OpenTofu
tofu init

# Validate configuration
tofu validate

# Plan changes
tofu plan

# Apply configuration
tofu apply
```

## Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `openwrt_protocol` | string | `"https"` | Protocol (https/http) |
| `openwrt_host` | string | `"example.com"` | Access point hostname/IP |
| `openwrt_username` | string | `"opentofu"` | Admin username |
| `openwrt_password` | string | `"opentofu"` | Admin password |
| `wifi_password_ssid_mgmt` | string | `"mgmt-password"` | Management password |
| `wifi_password_ssid_guest` | string | `"guest-password"` | Guest password |
| `wifi_password_ssid_iot` | string | `"iot-password"` | IoT password |

## Wireless Security

- **MGMT_5GHZ**: WPA2-PSK
- **MGMT_2GHZ**: WPA2-PSK
- **GUEST_5GHZ**: WPA2-PSK
- **GUEST_2GHZ**: WPA2-PSK
- **IOT_5GHZ**: WPA2-PSK
- **IOT_2GHZ**: WPA2-PSK

## Provider

This configuration uses the [foxboron/openwrt](https://github.com/foxboron/terraform-provider-openwrt) provider.

## References

- [OpenWrt User Guide](https://openwrt.org/docs/guide-user/start)
- [How to get rid of LuCI HTTPS certificate warnings](https://openwrt.org/docs/guide-user/luci/getting_rid_of_luci_https_certificate_warnings#option_binstalling_any_publicly_trusted_certificate)
- [Extend filesystem through USB Key](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration)
- [OpenWrt Bridged AP Guide](https://openwrt.org/docs/guide-user/network/wifi/wifiextenders/bridgedap)
