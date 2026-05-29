# Ansible Playbook for Talos PXE Boot Server

This playbook manages a Raspberry Pi running as a Talos PXE boot server using **nerdctl**, **containerd**, and **log2ram**.

## Overview

The playbook installs and configures:
- **raspi-hardening**: Mounts tmpfs for /var/log, /tmp, /var/tmp; disables swap
- **containerd-setup**: Installs containerd and nerdctl as Docker replacement
- **talos-pxe**: Deploys Talos PXE boot containers

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
- Generates docker-compose.yaml for Talos services
- Configures PXE network interfaces
- Generates iptables.conf template from role templates directory
- Starts booter and remote-config containers via nerdctl

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
containerd_version: "2.3.1"   # Containerd version to use
nerdctl_version: "2.3.1"     # Nerdctl version to use
nerdctl_checksum: sha256:... # Expected SHA256 checksum for nerdctl
backup_dir: /etc/backups      # Directory for fstab backups
```

### Templated Files

The playbook generates the following configuration files:

- `/etc/fstab` - Updated with tmpfs and swap entries
- `/etc/systemd/journald.conf` - Configured for volatile storage (backup created in `{{ backup_dir }}`)
- `/home/<user>/talos-pxe/docker-compose.yaml` - Talos services configuration
- `/home/<user>/talos-pxe/iptables.conf` - iptables configuration
- `/usr/local/bin/nerdctl` - Docker-compatible CLI (symlink)
- `/usr/local/bin/iptables` - iptables symlink for easier access

## Accessing Services

After playbook execution:

| Service     | Port   | Protocol | Description                    |
|-------------|--------|----------|--------------------------------|
| TFTP        | 69     | UDP      | PXE boot server                 |
| HTTP        | 8080   | TCP      | Remote configuration interface  |
| nerdctl     | N/A    | CLI      | Container management tool       |

## Container Management

After installation, use nerdctl to manage containers:

```bash
# Pull Talos images
nerdctl pull ghcr.io/siderolabs/booter:v0.3.0

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
