# OpenWrt Access Point Configuration

## Overview

This OpenTofu configuration manages a TP-Link Archer C7 acting as a WiFi access point for the MikroTik network. It configures network interfaces, wireless networks, and system packages for VLANs.

## Hardware

- **Model**: TP-Link Archer C7 v2
- **Role**: WiFi access point with VLAN passthrough

## VLANs

| VLAN ID | Network Interface | SSID (2.4GHz) | SSID (5GHz) | Purpose |
|--------|-------------------|---------------|-------------|---------|
| 10 | eth0.10 | OpenWrt-Management | OpenWrt-Management-5G | Management network |
| 60 | eth0.60 | OpenWrt-Guest | OpenWrt-Guest-5G | Guest WiFi |
| 100 | eth0.100 | OpenWrt-IoT | OpenWrt-IoT-5G | IoT devices |

## Prerequisites

1. OpenTofu (tofu) >= 1.5.0
2. OpenWrt with RPC API enabled (`luci-mod-rpc` and dependencies)
3. Access to OpenWrt device via HTTPS
4. `luci`, `luci-ssl`, `luasocket`, `luci-lib-ipkg`, `luci-compat` installed beforehand (required for the provider)

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

### Connection Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `openwrt_protocol` | string | `"https"` | Protocol (https/http) |
| `openwrt_host` | string | `"example.com"` | Access point hostname/IP |
| `openwrt_username` | string | `"opentofu"` | Admin username |
| `openwrt_password` | string | `"opentofu"` | Admin password |

### WiFi Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `wifi_password_ssid_mgmt` | string | `"mgmt-password"` | Management WiFi password |
| `wifi_password_ssid_guest` | string | `"guest-password"` | Guest WiFi password |
| `wifi_password_ssid_iot` | string | `"iot-password"` | IoT WiFi password |

### Network Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vlan_base_network` | string | `"10.42.0.0"` | Base network for VLAN subnets |
| `vlan_prefix_length` | number | `24` | CIDR prefix length per VLAN subnet |
| `vlan_start_id` | number | `10` | Starting VLAN ID |
| `vlan_end_id` | number | `100` | Ending VLAN ID |
| `vlan_names` | map | `{10="mgmt", 60="guest", 100="iot"}` | VLAN ID to name mappings |

### API Timeouts
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `openwrt_api_timeouts` | object | (see below) | API timeout settings for various operations |

Default `openwrt_api_timeouts`:
```hcl
{
  api = "5s"
  fs = {
    read_file    = "10s"
    remove_file  = "10s"
    write_file   = "10s"
  }
  opkg = {
    check_package      = "60s"
    install_packages   = "60s"
    remove_packages    = "60s"
    update_packages    = "60s"
  }
  service = {
    disable_service    = "20s"
    enable_service     = "20s"
    is_enabled         = "20s"
    list_services      = "20s"
    restart_service    = "20s"
    start_service      = "20s"
    stop_service       = "20s"
  }
  uci = {
    add              = "60s"
    commit_or_revert = "60s"
    delete           = "60s"
    get_all          = "60s"
    t_set            = "60s"
  }
}
```

## Usage Examples

### Example 1: Basic Provider Configuration
```hcl
terraform {
  required_providers {
    openwrt = {
      source = "foxboron/openwrt"
    }
  }
}

provider "openwrt" {
  user     = var.openwrt_username
  password = var.openwrt_password
  remote   = "https://${var.openwrt_host}"
}
```

### Example 2: Custom WiFi Passwords
```hcl
variable "wifi_password_ssid_mgmt" {
  default = "my-secure-management-password"
}

variable "wifi_password_ssid_guest" {
  default = "guest-access-2024"
}

variable "wifi_password_ssid_iot" {
  default = "iot-devices-only"
}
```

### Example 3: Custom Network Configuration
```hcl
variable "vlan_base_network" {
  default = "192.168.50.0"
}

variable "vlan_names" {
  default = {
    10  = "mgmt"
    60  = "guest"
    100 = "iot"
  }
}
```
This results in:
- Management: `192.168.60.0/24` (AP IP: `192.168.60.2`, gateway: `192.168.60.1`)
- Guest: `192.168.110.0/24` (AP IP: `192.168.110.2`)
- IoT: `192.168.150.0/24` (AP IP: `192.168.150.2`)

### Example 4: Extended API Timeouts
```hcl
variable "openwrt_api_timeouts" {
  default = {
    api = "10s"
    fs = {
      read_file   = "30s"
      remove_file = "30s"
      write_file  = "30s"
    }
    opkg = {
      check_package     = "120s"
      install_packages  = "120s"
      remove_packages   = "120s"
      update_packages   = "120s"
    }
    service = {
      disable_service  = "30s"
      enable_service   = "30s"
      is_enabled       = "30s"
      list_services    = "30s"
      restart_service  = "30s"
      start_service    = "30s"
      stop_service     = "30s"
    }
    uci = {
      add              = "120s"
      commit_or_revert = "120s"
      delete           = "120s"
      get_all          = "120s"
      t_set            = "120s"
    }
  }
}
```

## Wireless Security

| SSID | Band | Encryption | Special Settings |
|------|------|------------|-----------------|
| OpenWrt-Management | 2.4GHz | WPA2-PSK | Hidden |
| OpenWrt-Management-5G | 5GHz | WPA2-PSK | Hidden |
| OpenWrt-Guest | 2.4GHz | WPA2-PSK | Client isolation |
| OpenWrt-Guest-5G | 5GHz | WPA2-PSK | Client isolation |
| OpenWrt-IoT | 2.4GHz | WPA2-PSK | - |
| OpenWrt-IoT-5G | 5GHz | WPA2-PSK | - |

## Packages

The following packages are installed automatically via `openwrt_opkg`:

### AP Mode Packages
- `ath10k-firmware-qca988x` - Firmware for the 5GHz radio
- `bridge` - Bridge utilities
- `kmod-ath10k` - Kernel module for Atheros QCA988x
- `wpad-basic` - WPA supplicant/hostapd for WiFi authentication

### VLAN Packages
- `swconfig` - Switch configuration utility for VLAN support

## Services

| Service | Status | Description |
|---------|--------|-------------|
| `dnsmasq` | Disabled | DHCP/DNS server (handled by MikroTik router) |
| `firewall` | Disabled | Firewall (handled by MikroTik router, AP is bridged) |

## Directory Structure

```
tplink/
├── backend.tf       # PostgreSQL backend configuration
├── network.tf       # Network interfaces and switch VLAN config
├── packages.tf      # Package installation (firmware, swconfig)
├── providers.tf     # OpenWrt provider definition
├── README.md        # This file
├── services.tf      # Service management (dnsmasq, firewall)
├── variables.tf     # Input variables and locals
└── wireless.tf      # WiFi radio and SSID configuration
```

## Radio Configuration

### radio0 (2.4GHz)
- **Chipset**: Atheros QCA988x (platform/ahb/18100000.wmac)
- **Channel**: 1
- **HT Mode**: HT20
- **Country**: FR

### radio1 (5GHz)
- **Chipset**: Atheros QCA988x (pci0000:00/0000:00:00.0)
- **Channel**: 36
- **HT Mode**: VHT80
- **Country**: FR

## Network Configuration

The AP is configured as a bridged access point:
- **WAN** (`eth1`): No protocol (trunk to MikroTik)
- **Switch** (`switch0`): VLAN enabled, ports `0t 1t` for all VLANs
- **LAN interfaces**: Static IPs on each VLAN interface (`eth0.X`)
- **Management**: Gateway and DNS point to MikroTik router

## Provider

This configuration uses the [foxboron/openwrt](https://github.com/foxboron/terraform-provider-openwrt) provider.

## References

- [OpenWrt User Guide](https://openwrt.org/docs/guide-user/start)
- [How to get rid of LuCI HTTPS certificate warnings](https://openwrt.org/docs/guide-user/luci/getting_rid_of_luci_https_certificate_warnings#option_binstalling_any_publicly_trusted_certificate)
- [Extend filesystem through USB Key](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration)
- [OpenWrt Bridged AP Guide](https://openwrt.org/docs/guide-user/network/wifi/wifiextenders/bridgedap)
