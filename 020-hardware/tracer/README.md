# Ansible Playbook for Talos PXE Boot Server

This playbook manages a Raspberry Pi running as a Talos PXE boot server using **nerdctl**, **containerd**, and **log2ram**.

## Overview

The playbook installs and configures:
- **raspi-hardening**: Mounts tmpfs for /var/log, /tmp, /var/tmp; disables swap
- **containerd-setup**: Installs containerd and nerdctl as Docker replacement
- **talos-pxe**: Deploys matchbox (iPXE profiles over HTTP) and dnsmasq (proxy DHCP + TFTP) to PXE boot Talos nodes

## Requirements

- Raspberry Pi OS (bookworm or compatible)
- Ansible 2.9+
- Root/sudo access
- Network connectivity for package installation
- Supported hardware: Raspberry Pi 4+ or compatible ARM64 devices

## Quick Start

```bash
cd /path/to/ansible
ansible-playbook -i inventories/inventory.yml playbooks/main.yml
```

## Usage Examples

**Run with tags:**
```bash
# Install only raspi-hardening role
ansible-playbook -i inventories/inventory.yml playbooks/main.yml --tags ram

# Install containerd and talos only
ansible-playbook -i inventories/inventory.yml playbooks/main.yml --tags containerd --tags talos
```

## Architecture

### Roles

#### raspi-hardening
Configures the Pi for reduced wear and extended storage life:
- Mounts /var/log on tmpfs (volatile storage via log2ram)
- Mounts /tmp and /var/tmp on tmpfs
- Disables swap to extend SSD lifespan (removes dphys-swapfile if present)
- Configures journald for volatile storage
- Creates backup of /etc/fstab before modifications
- Copies journald.conf template from role templates directory

#### containerd-setup
Installs containerd and nerdctl as a Docker replacement:
- Downloads and installs containerd (rootless setup)
- Installs nerdctl (Docker-compatible CLI)
- Creates symlink from `docker` to `nerdctl`
- Creates symlink from `/usr/sbin/iptables` to `/usr/local/bin/iptables`
- Enables containerd service

Note: Containerd can be installed via `containerd-rootless-setuptool.sh` for rootless operation.
The role also configures necessary kernel parameters (net.ipv4.ip_unprivileged_port_start).

#### talos-pxe
Deploys Talos PXE boot services:
- Downloads the Talos kernel and initramfs from the Image Factory for the configured schematic/version
- Generates matchbox profiles and groups under `matchbox/` (served over HTTP on `matchbox_port`)
- Generates docker-compose.yaml for matchbox, dnsmasq and remote-config
- Configures the PXE network interface
- Starts the containers via nerdctl

The boot chain is: PXE firmware -> dnsmasq proxy DHCP/TFTP chainloads iPXE -> iPXE fetches `/boot.ipxe` from matchbox -> matchbox renders the `talos` profile (kernel/initramfs downloaded locally, so no HTTPS is required in iPXE) -> Talos fetches its per-node config from remote-config (`/metadata`).

To change the Talos version, update `talos_version` in the inventory and re-run the role (assets are stored per version under `matchbox/assets/`).

## Configuration

### Inventory Variables

```yaml
# /inventories/inventory.yml
tmpfs_log_size: "50M"         # Size of /var/log tmpfs mount
tmpfs_tmp_size: "500M"        # Size of /tmp tmpfs mount
tmpfs_var_tmp_size: "30M"     # Size of /var/tmp tmpfs mount
journald_storage: volatile     # Use volatile storage for logs
journald_max_use: "50M"       # Maximum journald usage
docker_log_max_size: "10m"    # Max Docker log size per container
docker_log_max_files: 3       # Max log files to keep
network_interface: eth0       # Primary network interface
pxe_tftp_port: 69             # TFTP port for PXE boot
http_port: 8080               # HTTP port for remote configuration
matchbox_port: 8082           # HTTP port for the matchbox iPXE profiles
talos_version: v1.13.7        # Talos version to PXE boot
talos_factory_schematic: ...  # Image Factory schematic for the PXE kernel/initramfs (empty by default)
containerd_version: "2.3.1"   # Containerd version to use
nerdctl_version: "2.3.1"     # Nerdctl version to use
nerdctl_checksum: sha256:... # Expected SHA256 checksum for nerdctl
backup_dir: /etc/backups      # Directory for fstab backups
```

### Templated Files

The playbook generates the following configuration files:

- `/etc/fstab` - Updated with tmpfs and swap entries
- `/etc/systemd/journald.conf` - Configured for volatile storage (backup created in `{{ backup_dir }}`)
- `/home/<user>/talos-pxe/docker-compose.yaml` - matchbox, dnsmasq and remote-config services
- `/home/<user>/talos-pxe/matchbox/profiles/talos.json` - matchbox Talos iPXE profile
- `/home/<user>/talos-pxe/matchbox/groups/default.json` - matchbox default group (matches all machines)
- `/home/<user>/talos-pxe/matchbox/assets/<version>/` - Talos kernel and initramfs served by matchbox
- `/usr/local/bin/nerdctl` - Docker-compatible CLI (symlink)
- `/usr/local/bin/iptables` - iptables symlink for easier access

## Accessing Services

After playbook execution:

| Service     | Port   | Protocol | Description                    |
|-------------|--------|----------|--------------------------------|
| TFTP        | 69     | UDP      | dnsmasq TFTP (iPXE chainload)  |
| Proxy DHCP  | 67     | UDP      | dnsmasq proxy DHCP             |
| HTTP        | 8080   | TCP      | remote-config interface         |
| HTTP        | 8082   | TCP      | matchbox iPXE profiles         |
| nerdctl     | N/A    | CLI      | Container management tool       |

## Container Management

After installation, use nerdctl to manage containers:

```bash
# Pull Talos images
nerdctl pull quay.io/poseidon/matchbox:v0.11.0

# List running containers
nerdctl ps

# View container logs
nerdctl logs <container_name>

# Stop containers
nerdctl compose -f /home/<user>/talos-pxe/docker-compose.yaml down

# Restart services
nerdctl compose -f /home/<user>/talos-pxe/docker-compose.yaml up -d
```

## Troubleshooting

**Check containerd status:**
```bash
systemctl status containerd
```

**Check container status:**
```bash
nerdctl ps -a
```

**View container logs:**
```bash
nerdctl logs <container_name>
```

**Verify tmpfs mounts:**
```bash
mount | grep tmpfs
```

**Check swap status:**
```bash
swapon --show
```

## Notes

- This setup uses containerd with nerdctl for container management
- The `docker` command is symlinked to `nerdctl` for compatibility
- All logging is configured to use tmpfs to extend storage life
- Swap is disabled by default to protect SSD lifespan
- Consider adjusting tmpfs sizes based on your workload requirements
- The journald.conf template is copied from `raspi-hardening/templates/` and backed up before modification
