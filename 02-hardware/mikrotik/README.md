# MikroTik Homelab Network Infrastructure

## Overview

This Terraform configuration manages a MikroTik CRS328-24P-4S+RM switch with VLAN segmentation for a homelab environment. All network subnets are derived from a single base network variable, making the configuration highly customizable.

## Networking Architecture

### Switch
- **Model**: MikroTik CRS328-24P-4S+RM
- **Role**: Router backbone with VLAN filtering, DHCP servers, and firewall rules

### VLAN Structure
All VLANs derive from `vlan_base_network` variable:
```
VLAN 10: 10.42.0.0/24      # Management (gateway 10.42.0.1)
VLAN 20: 10.42.20.0/24     # Kubernetes (gateway 10.42.20.1)
VLAN 30: 10.42.30.0/24     # Proxmox (gateway 10.42.30.1)
VLAN 40: 10.42.40.0/24     # Load Balancer (gateway 10.42.40.1)
VLAN 50: 10.42.50.0/24     # Windows (gateway 10.42.50.1)
VLAN 60: 10.42.60.0/24     # Guest WiFi (gateway 10.42.60.1)
VLAN 100: 10.42.100.0/24   # IoT devices (gateway 10.42.100.1)
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
  default = "192.168.100.0"
}

variable "vlan_prefix_length" {
  default = 24
}

variable "vlan_start_id" {
  default = 100
}
```
Results in:
- VLAN 100: `192.168.100.100.0/24`
- VLAN 200: `192.168.100.200.0/24`

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

### Example 5: Complete Example with All Variables
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
    40  = "lb"
    50  = "windows"
    60  = "guest"
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

### IP Addressing
- Gateway IPs automatically calculated as first usable address
- DHCP server address pools (100-254 range per VLAN)

### Firewall Rules
- Priority-based inter-VLAN routing (higher → lower VLAN)
- IoT internet denial rules
- DNS lockdown for restricted VLANs
- MASQUERADE NAT for internet access

### DHCP
- DHCP servers per VLAN interface
- DHCP network definitions with gateway and DNS
- Static IP reservations based on MAC addresses

## Directory Structure

```
mikrotik/
├── main.tf          # Not used; replaced by separate files
├── providers.tf     # Provider definitions
├── backend.tf       # Local backend configuration
├── variables.tf     # Input variables and locals
├── vlans.tf         # Bridge, VLANs, IP addressing, DHCP
├── firewall.tf      # Firewall rules
├── dhcp.tf          # Static DHCP leases
└── README.md        # This file
```

## DNS Configuration

Different VLANs have different DNS settings:
- **VLAN 10 (mgmt)**: Uses management VLAN gateway as DNS
- **VLAN 20 (k8s)**: Uses Cloudflare (1.1.1.1, 9.9.9.9)
- **VLAN 30 (proxmox)**: Uses Quad9 (1.1.1.1, 9.9.9.9)
- **Other VLANs**: Uses Cloudflare (1.1.1.1, 9.9.9.9)

## Security Features

- **IoT Lockdown**: IoT VLAN (100) cannot access DNS except through router
- **Guest Isolation**: Guest VLAN (60) blocked from internal DNS
- **Inter-VLAN Routing**: Only higher priority VLANs can route to lower
- **Default Deny**: East-west traffic dropped unless explicitly allowed

## References

- [Getting Started Guide](https://mirceanton.com/posts/mikrotik-terraform-getting-started/)
- [TLS Provider Certificates](https://oneuptime.com/blog/post/2026-02-23-how-to-use-the-tls-provider-to-generate-certificates-in-terraform/view)
- [Terraform RouterOS Provider](https://github.com/terraform-routeros/terraform-provider-routeros)

## License

This project uses the MikroTik RouterOS Terraform Provider under the appropriate license terms.

## Contributing

To contribute, please fork this repository and submit pull requests with your improvements.
