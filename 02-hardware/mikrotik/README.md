# MikroTik Homelab Network Infrastructure

## Overview

This Terraform configuration manages a MikroTik CRS328-24P-4S+RM switch with VLAN segmentation for a homelab environment. All network subnets are derived from a single base network variable, making the configuration highly customizable.

## Networking Architecture

### Switch
- **Model**: MikroTik CRS328-24P-4S+RM
- **Role**: Router backbone with VLAN filtering, DHCP servers, and firewall rules

### Management Access

The router can be managed from two networks:

| Network | CIDR | Purpose |
|---------|------|---------|
| Default Management | `10.42.0.0/24` | Direct management access (pre-VLAN or ether1) |
| Management VLAN | `10.42.10.0/24` | Management via VLAN 10 (ether3, ether15, ether17) |

Both networks are explicitly allowed in the firewall input chain for router management. Traffic between these two CIDRs is also allowed in the forward chain, ensuring seamless access regardless of which management network you connect from.

### VLAN Structure
All VLANs derive from `vlan_base_network` variable:
```
VLAN 10: 10.42.10.0/24      # Management (gateway 10.42.10.1)
VLAN 20: 10.42.20.0/24      # Kubernetes (gateway 10.42.20.1)
VLAN 30: 10.42.30.0/24      # Proxmox (gateway 10.42.30.1)
VLAN 40: 10.42.40.0/24      # Windows (gateway 10.42.40.1)
VLAN 50: 10.42.50.0/24      # Guest WiFi (gateway 10.42.50.1)
VLAN 60: 10.42.60.0/24      # Load Balancer (gateway 10.42.60.1)
VLAN 100: 10.42.100.0/24    # IoT devices (gateway 10.42.100.1)
```

## Quick Start

### Prerequisites
1. Opentofu (tofu) >= 1.5.0
2. MikroTik RouterOS Provider (community)
3. Access to your MikroTik switch via HTTPS

### Installation

```bash
# Initialize Opentofu
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
| `routeros_protocol` | string | `"https"` | Protocol (https/http) |
| `routeros_host` | string | `"example.com"` | Switch hostname/IP |
| `routeros_username` | string | `"opentofu"` | Admin username |
| `routeros_password` | string | `"opentofu"` | Admin password |
| `routeros_insecure` | bool | `false` | Skip TLS verification |

### Network Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vlan_base_network` | string | `"10.42.0.0"` | **Base network prefix** |
| `vlan_filtering` | bool | `false` | Bridge VLAN filtering, enable to enforce vlan firewall |
| `vlan_prefix_length` | number | `24` | CIDR mask per VLAN |
| `vlan_start_id` | number | `10` | First VLAN ID |
| `vlan_end_id` | number | `100` | Last VLAN ID |
| `vlan_names` | map | see defaults | VLAN ID → name mapping |

### DNS Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `upstream_primary_dns` | string | `"1.1.1.1"` | Primary DNS |
| `upstream_secondary_dns` | string | `"9.9.9.9"` | Secondary DNS |

## Usage Examples

### Example 1: Standard Configuration (Default Values)
```terraform
resource "routeros_ip_firewall_filter" "fasttrack" {
  chain = "forward"
  connection_state = "established,related"
  action = "fasttrack-connection"
}
```

### Example 2: Custom Network Range
```terraform
variable "vlan_base_network" {
  default = "192.168.0.0"
}

variable "vlan_prefix_length" {
  default = 24
}

variable "vlan_start_id" {
  default = 100
}
```
Results in:
- VLAN 100: `192.168.100.0/24`
- VLAN 200: `192.168.200.0/24`

The `cidrsubnet()` function uses the third octet as the subnet index from a `/16` base.

### Example 3: Larger Subnets (/23)
```terraform
variable "vlan_base_network" {
  default = "10.0.0.0"
}

variable "vlan_prefix_length" {
  default = 23  # /23 = 512 hosts per VLAN
}
```

### Example 4: Custom VLAN Plan
```terraform
variable "vlan_base_network" {
  default = "172.16.0.0"
}

variable "vlan_prefix_length" {
  default = 26
}

variable "vlan_names" {
  default = {
    100  = "guest"
    102  = "k8s"
    104  = "vm"
    110  = "iot"
    120  = "worker"
  }
}
```

### Example 5: Static DHCP Leases
```terraform
# Static leases in dhcp.tf derive IPs from VLAN subnets automatically:
# jetkvm     → 10.42.10.10  (VLAN 10, MAC: 30:52:53:00:9E:0A)
# macbook    → 10.42.10.20  (VLAN 10, MAC: C8:A3:62:AA:C7:1A)
# k8s_cp1    → 10.42.20.10  (VLAN 20, hostname: sombra)
# proxmox1   → 10.42.30.10  (VLAN 30, hostname: roadhog)

# DNS records are auto-created as <name>.home.arpa
```

### Example 6: System Configuration (misc.tf)
```terraform
# These resources configure system-level settings:

# Disable IPv6
resource "routeros_ipv6_settings" "disable" {
  disable_ipv6 = "true"
}

# Interface lists for access control
resource "routeros_interface_list" "wan" { name = "WAN" }
resource "routeros_interface_list" "lan" { name = "LAN" }

# Restrict MAC server and Winbox to LAN only
resource "routeros_tool_mac_server" "mac_server" {
  allowed_interface_list = routeros_interface_list.lan.name
}
resource "routeros_tool_mac_server_winbox" "winbox_mac_access" {
  allowed_interface_list = routeros_interface_list.lan.name
}

# System identity and timezone
resource "routeros_system_identity" "identity" { name = "Router" }
resource "routeros_system_clock" "timezone" {
  time_zone_name       = "Europe/Paris"
  time_zone_autodetect = false
}
```

### Example 7: Complete Example with All Variables
```terraform
terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
    }
  }
}

provider "routeros" {
  host     = "https://router.example.com"
  username = "admin"
  password = "secret"
  insecure = false
}

variable "vlan_base_network" {
  description = "Base network for all VLAN subnets"
  type        = string
  default     = "10.42.0.0"
}

variable vlan_filtering {
  type        = bool
  default     = false
  description = "Bridge VLAN filtering, default is false to prevent locking user out."
}

variable "vlan_prefix_length" {
  description = "CIDR prefix length per VLAN subnet"
  type        = number
  default     = 24
}

variable "vlan_start_id" {
  description = "Starting VLAN ID"
  type        = number
  default     = 10
}

variable "vlan_end_id" {
  description = "Ending VLAN ID"
  type        = number
  default     = 100
}

variable "vlan_names" {
  description = "VLAN ID to name mappings"
  type        = map(string)
  default     = {
    10  = "mgmt"
    20  = "k8s"
    30  = "proxmox"
    40  = "windows"
    50  = "guest"
    60  = "lb"
    100 = "iot"
  }
}

variable "upstream_primary_dns" {
  description = "Primary upstream DNS server"
  type        = string
  default     = "1.1.1.1"
}

variable "upstream_secondary_dns" {
  description = "Secondary upstream DNS server"
  type        = string
  default     = "9.9.9.9"
}
```

## Generated Resources

The following resources are automatically generated from the variable configuration:

### Interfaces
- VLAN interfaces created for each configured VLAN ID
- Bridge ports with appropriate PVIDs
- LAN interface list members for bridge and all VLAN interfaces

### IP Addressing
- Gateway IPs automatically calculated as first usable address
- DHCP server address pools (100-254 range per VLAN)

### Firewall Rules
- Management access from default CIDR (10.42.0.0/24) and management VLAN CIDR (10.42.10.0/24)
- Bidirectional forwarding between default CIDR and management VLAN CIDR
- Inter-VLAN forwarding for all VLAN subnets (10.42.0.0/16)
- Priority-based inter-VLAN routing (higher → lower VLAN)
- IoT internet denial rules
- DNS lockdown for restricted VLANs
- MASQUERADE NAT for internet access

### System Configuration
- IPv6 disabled
- WAN/LAN interface lists
- LAN list populated with bridge and all VLAN interfaces
- MAC server and Winbox restricted to LAN

### DHCP
- DHCP servers per VLAN interface
- DHCP network definitions with gateway and DNS
- Static IP reservations based on MAC addresses
- Internal DNS records (.home.arpa) for static leases

### System Configuration
- IPv6 disabled
- WAN/LAN interface lists
- MAC server and Winbox restricted to LAN
- System identity and timezone (Europe/Paris)

## BGP Configuration

The `bgp.tf` file contains a **commented-out** BGP configuration for integration with Cilium/Talos:
- BGP instance (`routeros_routing_bgp_instance`)
- BGP template with listen mode for dynamic peers
- BGP connection for Talos subnet peers

Uncomment and configure the variables (`mikrotik_asn`, `cilium_asn`, `mikrotik_router_id`) to enable BGP peering.

## Directory Structure

```
mikrotik/
├── backend.tf                 # PostgreSQL backend configuration
├── bgp.tf                     # BGP configuration (commented out)
├── config-before-upgrade.rsc  # Backup of config before RouterOS upgrade
├── dhcp.tf                    # Static DHCP leases and DNS records
├── firewall.tf                # Firewall rules (input, forward, NAT)
├── misc.tf                    # System settings, interface lists, timezone
├── providers.tf               # Provider definitions
├── README.md                  # This file
├── routeros-backup.backup     # RouterOS backup file
├── variables.tf               # Input variables and locals
└── vlans.tf                   # Bridge, VLANs, IP addressing, DHCP
```

## DNS Configuration

Different VLANs have different DNS settings:
- **VLAN 10 (mgmt)**: Uses management VLAN gateway as DNS
- **VLAN 20 (k8s)**: Uses Cloudflare (1.1.1.1) + Quad9 (9.9.9.9)
- **VLAN 30 (proxmox)**: Uses Cloudflare (1.1.1.1) + Quad9 (9.9.9.9)
- **Other VLANs**: Uses Cloudflare (1.1.1.1) + Quad9 (9.9.9.9)

## Security Features

- **IoT Lockdown**: IoT VLAN (100) cannot access DNS except through router
- **Guest Isolation**: Guest VLAN (50) blocked from internal DNS
- **Inter-VLAN Routing**: Only higher priority VLANs can route to lower
- **Default Deny**: East-west traffic dropped unless explicitly allowed

## Enabling VLAN Filtering

**WARNING**: Enabling `vlan_filtering` on the bridge can lock you out if management access is not properly configured.

### Root Causes of Lockout (All Fixed in This Project)

| Issue | Effect | Fix |
|-------|--------|-----|
| Gateway IPs use `/32` mask | Gateway can't route to VLAN subnet devices | Changed to `/${var.vlan_prefix_length}` |
| LAN interface list empty | `drop_all_not_lan` rule drops ALL traffic | Bridge + all VLAN interfaces added to LAN list |
| `allow_bridge_to_vlans` uses `/24` source | VLAN 10 devices (`10.42.10.x`) can't forward | Changed to `/16` to cover all VLAN subnets |

### Prerequisites (already configured in this project)

1. **Gateway IPs use correct subnet mask** — `/${var.vlan_prefix_length}` (not `/32`) so the gateway can route to devices on each VLAN.

2. **LAN interface list populated** — bridge and all VLAN interfaces are members of the LAN list, preventing the `drop_all_not_lan` firewall rule from blocking management traffic.

3. **Forward rules cover all VLAN subnets** — `allow_bridge_to_vlans` uses `10.42.0.0/16` source/destination, covering all VLAN subnets.

4. **Management VLAN firewall rules** — Input chain rules explicitly allow management from:
   - Default CIDR (`10.42.0.0/24`)
   - Management VLAN CIDR (`10.42.10.0/24`)

5. **Bridge VLAN entries** — VLAN 10 (management) includes the bridge as tagged and management ports (ether3, ether15, ether17) as untagged.

6. **Inter-management traffic** — Forward chain rules allow bidirectional traffic between the default CIDR and management VLAN CIDR.

### Steps to Enable

1. Ensure your device is connected to a management port (ether3, ether15, or ether17) or has an IP in the `10.42.0.0/24` range.

2. Set the variable:
   ```terraform
   variable "vlan_filtering" {
     default = true
   }
   ```

3. Apply the configuration:
   ```bash
   tofu apply
   ```

4. Verify management access is still functional before proceeding with other changes.

### Recovery

If you lose access after enabling vlan_filtering:
- Connect via console/serial access
- Or connect to ether3/ether15/ether17 with an IP in `10.42.10.0/24`
- Or disable vlan_filtering via the variable and re-apply

## References

- [Getting Started Guide](https://mirceanton.com/posts/mikrotik-terraform-getting-started/)
- [TLS Provider Certificates](https://oneuptime.com/blog/post/2026-02-23-how-to-use-the-tls-provider-to-generate-certificates-in-terraform/view)
- [Terraform RouterOS Provider](https://github.com/terraform-routeros/terraform-provider-routeros)

## License

This project uses the MikroTik RouterOS Terraform Provider under the appropriate license terms.

## Contributing

To contribute, please fork this repository and submit pull requests with your improvements.
