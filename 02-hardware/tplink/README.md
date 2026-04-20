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
| `openwrt_port` | number | `8080` | OpenWrt HTTP port |
| `openwrt_username` | string | `"opentofu"` | Admin username |
| `openwrt_password` | string | `"opentofu"` | Admin password |

## Wireless Security

- **MGMT**: WPA3-SAE mixed mode
- **GUEST**: WPA2-PSK
- **IOT**: WPA2-PSK

## Provider

This configuration uses the [foxboron/openwrt](https://github.com/foxboron/terraform-provider-openwrt) provider.

## References

- [OpenWrt Terraform Provider](https://github.com/foxboron/terraform-provider-openwrt)
- [OpenWrt Bridged AP Guide](https://openwrt.org/docs/guide-user/network/wifi/wifiextenders/bridgedap)