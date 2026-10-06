# Talos Kubernetes Cluster

A [Talos Linux](https://www.talos.dev/) v1.13.2 Kubernetes v1.36.1 home lab cluster managed with [topf](https://github.com/postfinance/topf). This repository defines the full infrastructure-as-code configuration for a multi-node bare-metal and virtual machine cluster with opinionated network tuning, GitOps bootstrapping, and hardware-specific system extensions.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Cluster Layout](#cluster-layout)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Install Dependencies](#2-install-dependencies)
  - [3. Render Cluster Configuration](#3-render-cluster-configuration)
  - [4. Apply Configuration and Bootstrap](#4-apply-configuration-and-bootstrap)
- [Node Specifications](#node-specifications)
- [Configuration](#configuration)
  - [topf.yaml](#topfyaml)
  - [Patches](#patches)
  - [Schematics](#schematics)
  - [Secrets Management](#secrets-management)
- [Network Tuning](#network-tuning)
- [System Extensions](#system-extensions)
- [GitOps & Add-ons](#gitops--add-ons)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository contains everything needed to deploy and maintain a Talos Linux Kubernetes cluster in a home lab environment. It uses [topf](https://github.com/postfinance/topf) as the configuration management tool to generate the per-node machine configurations from a single `topf.yaml` file, per-node schematics, and a directory of patches.

The cluster consists of:

- **3 control plane nodes** — providing a highly available Kubernetes API (Raft-based etcd)
- **2 bare-metal worker nodes** — each with distinct hardware characteristics (Intel NUC, AMD Ryzen)
- **2 virtual machine workers** — one standard and one with NVIDIA GPU passthrough

The cluster is designed to be fully reproducible through declarative configuration, with secrets encrypted using [SOPS](https://github.com/getsops/sops) and PGP.

## Features

- **Talos Linux v1.13.2** — Immutable, minimal, and secure OS purpose-built for Kubernetes
- **Kubernetes v1.36.1** — Latest upstream Kubernetes with feature gates enabled
- **Cilium CNI** — eBPF-based networking with kube-proxy replacement
- **Flux CD** — GitOps-driven continuous delivery bootstrapped at cluster creation
- **Gateway API** — Experimental Gateway API resources installed automatically
- **Dynamic Resource Allocation** — Feature gate enabled for advanced resource scheduling
- **User Namespaces Support** — Feature gate enabled for improved workload isolation
- **BBR Congestion Control** — TCP BBR with FQ queueing discipline for optimal network performance
- **RPS/RFS Tuning** — Receive Packet Steering and Receive Flow Steering via DaemonSet
- **Hardware-Specific Extensions** — Intel/AMD microcode, NVIDIA GPU support, gVisor, NFS, and more
- **SOPS-Encrypted Secrets** — Cluster secrets encrypted with PGP via SOPS
- **Multi-Arch Ready** — Mixed hardware support across all nodes
- **Network Performance Tuning** — Comprehensive sysctl tuning for high-throughput workloads

## Cluster Layout

| Node | Role | IP Address | Hardware | Specs |
|------|------|------------|----------|-------|
| `sombra` | Control Plane | `*.10` | Bare-metal | NVMe disk, Intel |
| `lucio` | Control Plane | `*.20` | Bare-metal | NVMe disk, Intel |
| `zarya` | Control Plane | `*.30` | Bare-metal | SATA disk, Intel |
| `mercy` | Worker | `*.40` | NUC | Intel NUC, Intel ucode, i915 GPU |
| `winston` | Worker | `*.50` | Ryzen Desktop | AMD Ryzen, AMD ucode |
| `worker-vm` | Worker (VM) | `*.255` | Virtual Machine | QEMU guest agent, AMD ucode |
| `worker-vm-gpu` | Worker (VM) | `*.255` | Virtual Machine | NVIDIA GPU passthrough, AMD ucode |

- The IP addresses use the cluster subnet configured in `topf.yaml` (`data.subnet`).

## Prerequisites

Before you begin, ensure you have the following installed on your provisioning machine:

- [topf](https://github.com/postfinance/topf) — Configuration generation and apply tool
- [kubectl](https://kubernetes.io/docs/tasks/tools/) — Kubernetes CLI
- [sops](https://github.com/getsops/sops) — Secrets encryption/decryption
- A PGP key pair for SOPS encryption (the public key fingerprint is `3AFE004C7B67F70DCEA1B33187F191C9C8B81E94`)

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url> talos-cluster
cd talos-cluster
```

### 2. Install Dependencies

Install the required CLI tools on your provisioning machine:

```bash
# Install topf
brew install postfinance/tap/topf
# or: go install github.com/postfinance/topf/cmd/topf@latest
# or download a binary from https://github.com/postfinance/topf/releases

# Install sops
# See: https://github.com/getsops/sops/releases
```

### 3. Render Cluster Configuration

Run topf to generate the per-node machine configurations:

```bash
topf render -o clusterconfig
```

This produces:

- `clusterconfig/<hostname>.yaml` — Per-node Talos machine configuration
- `topf schematic-ids` shows the resolved Talos Factory image IDs per node

Cluster endpoint, versions, node IPs, and the cluster subnet are declared in `topf.yaml` — no environment variables are required.

### 4. Apply Configuration and Bootstrap

Apply the configuration to every node (nodes should already be booted into Talos Linux via PXE or ISO). This also bootstraps etcd on the first control plane node:

```bash
topf apply --auto-bootstrap
```

Retrieve the kubeconfig and talosconfig:

```bash
topf kubeconfig
topf talosconfig
```

After bootstrapping, Flux CD and Cilium are automatically installed via inline manifests and extra manifests defined in the cluster patches.

## Node Specifications

### Control Plane Nodes

All control plane nodes share the following configuration:

- Talos Linux v1.13.2
- Kubernetes v1.36.1
- etcd metrics enabled on port 2381
- `br_netfilter` kernel module with connection tracking tuning
- System extensions: Intel microcode, gVisor, Stargz Snapshotter
- Feature gates: `DynamicResourceAllocation`, `UserNamespacesSupport`
- DHCP networking on interface `eth0` / `eno1`

### Worker Nodes

Workers share common configuration (e.g., `bgp-policy: active` label) with per-node customization:

| Node | Special Configuration |
|------|----------------------|
| `mercy` | Tainted with `node.kubernetes.io/nuc`, Intel ucode + i915 extensions, NFS utils |
| `winston` | AMD ucode, NFS utils, custom kernel args for VLAN tagging |
| `worker-vm` | QEMU guest agent, PXE boot, VLAN `eth0.20`, AMD ucode |
| `worker-vm-gpu` | NVIDIA GPU extensions (container toolkit, kernel modules), QEMU guest agent, PXE boot, VLAN |

## Configuration

### topf.yaml

The main configuration file is `topf.yaml`. It defines:

- **Cluster metadata** — Cluster name, endpoint, Talos/Kubernetes versions
- **Nodes** — Host, role, IP, platform (metal/nocloud), and per-node schematic references
- **Data** — Shared template values (e.g. `subnet`) available to `.tpl` patches
- **Patches/secrets** — Paths to the `patches/` directory and `talsecret.sops.yaml`

### Patches

The `patches/` directory contains YAML files applied as configuration patches in directory order: `all/` (every node), `control-plane/` or `worker/` (by role), then `node/<host>/` (per node). Files ending in `.yaml.tpl` are rendered as Go templates first (context: cluster values, `{{ .Data.subnet }}`, `{{ .Node.Host }}`, …):

| File | Purpose |
|------|---------|
| `all/01-cluster.yaml` | CNI (none — handled by Cilium), pod/service CIDRs, API server feature gates, kube-proxy disabled, inline manifests (RPS tuning DaemonSet, `flux-system`/`cilium` namespaces), Gateway API and Flux install manifests |
| `all/02-machine.yaml.tpl` | Machine cert SANs, host DNS config, kubelet feature gates, user namespaces sysctl |
| `all/03-network.yaml` | Network performance sysctl tuning: TCP buffer sizes, BBR congestion control, connection backlog, keepalive, fast open, port range, IP forwarding |
| `all/04-firewall-common.yaml.tpl` | Host firewall: default deny ingress, kubelet/cilium/apid/cni-vxlan/hubble rules |
| `all/05-hostname.yaml.tpl` | `HostnameConfig` — sets the node hostname (stable hostname for the VMs) |
| `control-plane/` | `br_netfilter`, etcd metrics, eno1 DHCP, control-plane firewall rules, API server cert SANs |
| `worker/` | `br_netfilter`, `bgp-policy` label, worker firewall rules |
| `node/<host>/` | Install disk, per-node interfaces (bond0 + volumes for `winston`), labels, taints, per-node firewall rules |

### Schematics

Each node references a Talos Factory schematic in `schematics/` (per-node `schematicId: @schematics/<name>.yaml`) defining `extraKernelArgs` and system extensions. The schematic ID is computed locally; new/changed schematics must be submitted to the factory once with `topf render --submit-to-factory`. `topf schematic-ids` prints the resolved IDs.

### Secrets Management

Sensitive cluster secrets are encrypted with [SOPS](https://github.com/getsops/sops) using PGP:

- **`talsecret.sops.yaml`** — Contains the cluster ID, secret, bootstrap token, and all certificate key pairs (etcd, Kubernetes API, service account, OS).
- **`.sops.yaml`** — SOPS creation rules defining which files and fields are encrypted.

To decrypt secrets:

```bash
sops -d talsecret.sops.yaml > talsecret.yaml
```

To edit secrets:

```bash
sops talsecret.sops.yaml
```

The PGP key fingerprint configured for encryption is `3AFE004C7B67F70DCEA1B33187F191C9C8B81E94`.

## Network Tuning

The cluster includes comprehensive network performance tuning:

### sysctl Parameters

The `patches/all/03-network.yaml` file configures:

- **TCP Buffer Tuning** — Custom `tcp_rmem` and `tcp_wmem` values for high-throughput workloads
- **Socket Buffers** — 16 MB max receive/send buffers
- **Connection Backlog** — 65,535 listen backlog, 10,000 netdev backlog, 65,535 SYN backlog
- **BBR Congestion Control** — TCP BBR with Fair Queueing (FQ) qdisc
- **Connection Reuse** — `tcp_tw_reuse` enabled, reduced FIN timeout
- **Keepalive** — 10-minute idle, 30-second interval, 5 probes
- **TCP Fast Open** — Enabled (mode 3: both client and server)
- **Ephemeral Port Range** — Expanded to 1024–65535

### RPS/RFS

The RPS/RFS DaemonSet is defined as an inline manifest in `patches/all/01-cluster.yaml` and automatically:
- Enables Receive Packet Steering (RPS) on all RX queues using all available CPUs
- Configures Receive Flow Steering (RFS) with 32,768 flow entries and 4,096 flow count per queue

## System Extensions

Each node uses a customized Talos image built with specific system extensions via [Talos Factory](https://factory.talos.dev/):

| Extension | Nodes | Purpose |
|-----------|-------|---------|
| `intel-ucode` | Control planes, mercy | Intel CPU microcode updates |
| `amd-ucode` | winston, worker-vm, worker-vm-gpu | AMD CPU microcode updates |
| `i915` | mercy | Intel integrated GPU support |
| `gvisor` | All nodes | gVisor sandboxed container runtime |
| `nvidia-container-toolkit-lts` | worker-vm-gpu | NVIDIA container runtime (LTS branch) |
| `nvidia-open-gpu-kernel-modules-lts` | worker-vm-gpu | NVIDIA open-source kernel modules (LTS) |
| `nonfree-kmod-nvidia-lts` | worker-vm-gpu | NVIDIA proprietary kernel modules (LTS) |
| `nfs-utils` | Workers | NFS client utilities |
| `nfsd` | Workers | NFS server daemon |
| `stargz-snapshotter` | All nodes | Stargz lazy-loading image snapshotter |
| `qemu-guest-agent` | worker-vm, worker-vm-gpu | QEMU guest integration |
| `uhid` | worker-vm, worker-vm-gpu | User-space HID device support |
| `uinput` | worker-vm, worker-vm-gpu | User-space input device support |

## GitOps & Add-ons

The cluster is bootstrapped with GitOps and networking add-ons automatically via extra manifests defined in `patches/all/01-cluster.yaml`:

- **[Flux CD](https://fluxcd.io/)** — Installed from the latest release manifest. Manages all cluster workloads through GitOps reconciliation.
- **[Cilium](https://cilium.io/)** — kube-proxy replacement providing eBPF-based networking, observability, and security. The `cilium` namespace is pre-created at bootstrap.
- **[Gateway API](https://gateway-api.sigs.k8s.io/)** — Experimental Gateway API CRDs installed from the v1.5.1 release.

Since `cluster.proxy.disabled` is set to `true`, kube-proxy is not installed — Cilium handles all service networking.

## Contributing

Contributions are welcome and encouraged! Whether you're fixing a bug, improving documentation, or adding a new feature, please follow these guidelines:

1. **Fork the repository** and create a feature branch from `main`.
2. **Make your changes** — Keep them focused and well-documented.
3. **Test your configuration** by running `topf render -o clusterconfig` to ensure no errors.
4. **Submit a pull request** with a clear description of the changes and any relevant context.

### Commit Conventions

- Use clear, descriptive commit messages
- Prefix commits with the area of change (e.g., `patches:`, `config:`, `docs:`)
- Keep commits atomic — one logical change per commit

### Reporting Issues

If you encounter problems, please open an issue with:

- A description of the problem
- Your environment details (Talos version, hardware, etc.)
- Steps to reproduce
- Relevant logs or error messages

## License

This project is provided for educational and personal use. No license is explicitly specified — if you adapt it for your own cluster, attribution is appreciated but not required.

---

*Built with [Talos Linux](https://www.talos.dev/), [topf](https://github.com/postfinance/topf), and [SOPS](https://github.com/getsops/sops).*

## References
 - https://www.roosmaa.net/blog/2024/setting-up-zfs-on-talos/
