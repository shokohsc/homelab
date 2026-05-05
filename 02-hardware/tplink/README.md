# OpenWrt Access Point Configuration

## Overview

This OpenTofu configuration manages a TP-Link Archer C7 acting as a WiFi access point for the MikroTik network. It configures network interfaces, wireless networks, and system packages for VLANs.

## Hardware

- **Model**: TP-Link Archer C7 v2
- **Role**: WiFi access point with VLAN passthrough

## VLANs

| VLAN ID | Network Interface | SSID (2.4GHz + 5GHz) | Purpose |
|--------|-------------------|----------------------|---------|
| 10 | eth0.10 | OpenWrt-Management | Management network |
| 50 | eth0.50 | OpenWrt-Guest | Guest WiFi |
| 100 | eth0.100 | OpenWrt-IoT | IoT devices |

Each SSID is broadcast on both 2.4GHz and 5GHz with the same name. The Management SSID is hidden.

## Prerequisites

1. OpenTofu (tofu) >= 1.5.0
2. OpenWrt with RPC API enabled (`luci-mod-rpc` and dependencies)
3. Access to OpenWrt device via HTTP (default) or HTTPS (requires manual certificate setup)
4. `luci`, `luci-ssl`, `luasocket`, `luci-lib-ipkg`, `luci-compat` installed beforehand (required for the provider)

## Manual Setup

The following steps must be done manually through the LuCI web UI or SSH before applying Terraform:

1. **Upload SSH public key**: Add your public SSH key through the LuCI UI (System → Administration → SSH-Keys) for passwordless access.

2. **Configure HTTPS certificate**: To access LuCI via HTTPS without browser SSL warnings, upload a trusted TLS certificate and key:
   - Copy your certificate to `/etc/uhttpd.crt`
   - Copy your private key to `/etc/uhttpd.key`
   - Restart uhttpd: `/etc/init.d/uhttpd restart`

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
| `openwrt_protocol` | string | `"http"` | Protocol (https/http) |
| `openwrt_host` | string | `"example.com"` | Access point hostname/IP |
| `openwrt_username` | string | `"opentofu"` | Admin username |
| `openwrt_password` | string | `"opentofu"` | Admin password |

### WiFi Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `wifi_password_ssid_mgmt` | string | `"mgmt-password"` | Management WiFi password |
| `wifi_password_ssid_guest` | string | `"guest-password"` | Guest WiFi password |
| `wifi_password_ssid_iot` | string | `"iot-password"` | IoT WiFi password |

### System Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `system_timezone` | string | `"UTC"` | Device timezone |

### Network Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vlan_base_network` | string | `"10.42.0.0"` | Base network for VLAN subnets |
| `vlan_prefix_length` | number | `24` | CIDR prefix length per VLAN subnet |
| `vlan_start_id` | number | `10` | Starting VLAN ID |
| `vlan_end_id` | number | `100` | Ending VLAN ID |
| `vlan_names` | map | `{10="mgmt", 50="guest", 100="iot"}` | VLAN ID to name mappings |

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
    50  = "guest"
    100 = "iot"
  }
}
```
This results in:
- Management: `192.168.10.0/24` (AP IP: `192.168.10.2`, gateway: `192.168.10.1`)
- Guest: `192.168.50.0/24`
- IoT: `192.168.100.0/24`

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

| SSID | Bands | Encryption | Special Settings |
|------|-------|------------|-----------------|
| OpenWrt-Management | 2.4GHz + 5GHz | WPA2-PSK | Hidden SSID |
| OpenWrt-Guest | 2.4GHz + 5GHz | WPA2-PSK | Client isolation |
| OpenWrt-IoT | 2.4GHz + 5GHz | WPA2-PSK | - |

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
├── backend.tf       # Local backend configuration
├── dhcp.tf          # DHCP configuration (disabled)
├── network.tf       # Network interfaces and switch VLAN config
├── packages.tf      # Package installation (firmware, swconfig)
├── providers.tf     # OpenWrt provider definition
├── README.md        # This file
├── services.tf      # Service management (dnsmasq, firewall)
├── system.tf        # System settings (hostname, timezone)
├── variables.tf     # Input variables and locals
└── wireless.tf      # WiFi radio and SSID configuration
```

## Radio Configuration

### radio0 (5GHz)
- **Path**: pci0000:00/0000:00:00.0
- **Channel**: 36
- **HT Mode**: VHT80
- **Country**: US

### radio1 (2.4GHz)
- **Path**: platform/ahb/18100000.wmac
- **Channel**: 1
- **HT Mode**: HT20
- **Country**: US

## Network Configuration

The AP is configured as a bridged access point:
- **Trunk uplink**: LAN port 1 (switch port 2) carries tagged VLANs 10, 50, 100
- **Switch** (`switch0`): VLAN enabled, per-VLAN port assignments:
  - VLAN 10: `0t 1t 2t 3` (CPU + WAN + LAN_1 trunk, LAN_2 untagged)
  - VLAN 50: `0t 1t 2t 4` (CPU + WAN + LAN_1 trunk, LAN_3 untagged)
  - VLAN 100: `0t 1t 2t 5` (CPU + WAN + LAN_1 trunk, LAN_4 untagged)
- **LAN interfaces**: VLAN subinterfaces `eth0.10`, `eth0.50`, `eth0.100` bridged into `br-mgmt`, `br-guest`, `br-iot`
- **Management**: Static IP on `br-mgmt`, gateway and DNS point to MikroTik router

### Switch Port Mapping (Archer C7 v2)

| Physical Port | Switch Port | Role |
|---------------|-------------|------|
| WAN | 1 | Trunk (tagged) |
| LAN 1 | 2 | Trunk (tagged) to MikroTik |
| LAN 2 | 3 | Management (VLAN 10, untagged) |
| LAN 3 | 4 | Guest (VLAN 50, untagged) |
| LAN 4 | 5 | IoT (VLAN 100, untagged) |

The WAN port and LAN_1 are both configured as trunk ports with tagged VLANs. LAN_2, LAN_3, and LAN_4 are access ports for their respective VLANs.

## DHCP

The AP does **not** run its own DHCP server. All DHCP is handled by the MikroTik router:
- Devices on **OpenWrt-Management** receive IPs from `10.42.10.100-254` via MikroTik
- Devices on **OpenWrt-Guest** receive IPs from `10.42.50.100-254` via MikroTik
- Devices on **OpenWrt-IoT** receive IPs from `10.42.100.100-254` via MikroTik

The AP itself gets a static IP (`10.42.10.2`) on the management VLAN for administrative access.

## Provider

This configuration uses the [foxboron/openwrt](https://github.com/foxboron/terraform-provider-openwrt) provider.

## References

- [OpenWrt User Guide](https://openwrt.org/docs/guide-user/start)
- [How to get rid of LuCI HTTPS certificate warnings](https://openwrt.org/docs/guide-user/luci/getting_rid_of_luci_https_certificate_warnings#option_binstalling_any_publicly_trusted_certificate)
- [Extend filesystem through USB Key](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration)
- [OpenWrt Bridged AP Guide](https://openwrt.org/docs/guide-user/network/wifi/wifiextenders/bridgedap)
