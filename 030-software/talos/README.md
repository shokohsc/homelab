# Talos Kubernetes Cluster

A [Talos Linux](https://www.talos.dev/) v1.13.7 Kubernetes v1.36.2 home lab cluster managed with [talstomize](https://github.com/mirceanton/talstomize). This repository defines the full infrastructure-as-code configuration for a multi-node bare-metal and virtual machine cluster with opinionated network tuning, GitOps bootstrapping, and hardware-specific system extensions.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Cluster Layout](#cluster-layout)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Install Dependencies](#2-install-dependencies)
  - [3. Configure Environment Variables](#3-configure-environment-variables)
  - [4. Generate Cluster Configuration](#4-generate-cluster-configuration)
  - [5. Apply Configuration to Nodes](#5-apply-configuration-to-nodes)
  - [6. Bootstrap the Cluster](#6-bootstrap-the-cluster)
- [Node Specifications](#node-specifications)
- [Configuration](#configuration)
  - [Talstomize Config](#talstomize-config)
  - [Patches](#patches)
  - [Secrets Management](#secrets-management)
- [Network Tuning](#network-tuning)
- [System Extensions](#system-extensions)
- [GitOps & Add-ons](#gitops--add-ons)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository contains everything needed to deploy and maintain a Talos Linux Kubernetes cluster in a home lab environment. It uses [talstomize](https://github.com/mirceanton/talstomize) as the configuration management tool to generate the per-node machine configurations from a single `talstomize.yaml` file.

The cluster consists of:

- **3 control plane nodes** — providing a highly available Kubernetes API (Raft-based etcd)
- **2 bare-metal worker nodes** — each with distinct hardware characteristics (Intel NUC, AMD Ryzen)
- **2 virtual machine workers** — one standard and one with NVIDIA GPU passthrough

The cluster is designed to be fully reproducible through declarative configuration, with secrets encrypted using [SOPS](https://github.com/getsops/sops) and PGP.

## Features

- **Talos Linux v1.13.7** — Immutable, minimal, and secure OS purpose-built for Kubernetes
- **Kubernetes v1.36.2** — Latest upstream Kubernetes with feature gates enabled
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

> The IP addresses use a configurable subnet via the `TALOS_SUBNET` environment variable.

## Prerequisites

Before you begin, ensure you have the following installed on your provisioning machine:

- [talstomize](https://github.com/mirceanton/talstomize) — Configuration generation tool
- [talosctl](https://www.talos.dev/v1.13/introduction/quickstart/) — Talos CLI
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
# Install talstomize (see repository for latest instructions)
# Install talosctl
curl -sL https://talos.dev/install | sh

# Install sops
# See: https://github.com/getsops/sops/releases
```

> Pin talstomize to the **v0.1.0-rc.1** release. From `v0.1.0-rc.2` onwards talstomize
> embeds Talos v1.14 machinery, which generates configs using the v1.14 split-document
> API that a Talos v1.13 node refuses to load.

### 3. Configure Environment Variables

The configuration uses several environment variables as placeholders. Create a `.env` file or export them in your shell:

```bash
export TALOS_DOMAIN="home.arpa"        # Your domain
export TALOS_SUBNET="10.42.20"         # Your cluster subnet
export MGMT_SUBNET="10.42.10"         # Your management subnet
# Optional: export CA_CERT if using custom CA certificates
```

### 4. Generate Cluster Configuration

Run talstomize to generate the per-node machine configurations and the `talosconfig`:

```bash
talstomize build
```

Use `-o <dir>` to write somewhere else, `talstomize apply -f _out --node sombra [-- ...]`
to push a config with talosctl, and `talstomize diff -f _out` to see what would change
on the live nodes.

This produces:

- `_out/<hostname>.yaml` — Per-node Talos machine configuration
- `_out/talosconfig` — Talos CLI configuration for cluster access

### 5. Apply Configuration to Nodes

Apply the generated configuration to each node. Nodes should already be booted into Talos Linux (PXE or ISO install).

```bash
# Bootstrap a control plane node
talosctl apply-config --insecure \
  --nodes <node-ip> \
  --file _out/sombra.yaml

# Repeat for other control plane and worker nodes
```

### 6. Bootstrap the Cluster

Once the control plane nodes are configured, bootstrap etcd:

```bash
talosctl bootstrap \
  --nodes 10.42.20.10 \
  --endpoints 10.42.20.10

# Retrieve the kubeconfig
talosctl kubeconfig \
  --nodes 10.42.20.10 \
  --endpoints 10.42.20.10
```

After bootstrapping, Flux CD and Cilium are automatically installed via inline manifests and extra manifests defined in the cluster patches.

## Node Specifications

### Control Plane Nodes

All control plane nodes share the following configuration:

- Talos Linux v1.13.7
- Kubernetes v1.36.2
- etcd metrics enabled on port 2381
- `br_netfilter` kernel module with connection tracking tuning
- System extensions: Intel microcode, gVisor, Stargz Snapshotter
- Feature gates: `DynamicResourceAllocation`, `UserNamespacesSupport`
- DHCP networking on interface `eno1`

### Worker Nodes

Workers share common configuration (e.g., `bgp-policy: active` label) with per-node customization:

| Node | Special Configuration |
|------|----------------------|
| `mercy` | Tainted with `node.kubernetes.io/nuc`, Intel ucode + i915 extensions, NFS utils |
| `winston` | AMD ucode, NFS utils, custom kernel args for VLAN tagging |
| `worker-vm` | QEMU guest agent, PXE boot, VLAN `ens18.20`, AMD ucode |
| `worker-vm-gpu` | NVIDIA GPU extensions (container toolkit, kernel modules), QEMU guest agent, PXE boot, VLAN `eth0.20` |

## Configuration

### Talstomize Config

The main configuration file is `talstomize.yaml`. It defines:

- **Cluster metadata** — Cluster name, Talos/Kubernetes versions, API server SANs, secret bundle
- **Nodes** — IP, role (control plane/worker), disk, labels, taints, and per-node patches
- **Patches** — References to patch files applied to all nodes, or per role
- **Schematics** — System extensions and kernel arguments for the Talos node image, cluster-wide or per node
- **Installer** — Talos version and factory installer image (schematic or pinned image)

> talstomize only knows how to resolve **metal** schematics, so the two PXE-booted VMs
> (`worker-vm`, `worker-vm-gpu`) pin their `nocloud-installer` image by URL. Everything
> that used to be a talhelper first-class field (network interfaces, install disk, kernel
> modules, node labels, CNI, inline manifests) is expressed as a patch instead.

### Patches

The `patches/` directory contains YAML files that are applied as configuration patches:

| File | Purpose |
|------|---------|
| `cluster.yaml` | Cluster-wide patches: CNI disabled (Cilium), API server feature gates, kube-proxy disabled, the RPS/RFS DaemonSet plus inline namespaces for `flux-system` and `cilium` as inline manifests, Gateway API and Flux install manifests |
| `machine.yaml` | Machine-level patches: cert SANs, host DNS config, kubelet feature gates, user namespaces sysctl |
| `network.yaml` | Network performance sysctl tuning: TCP buffer sizes, BBR congestion control, connection backlog, keepalive, fast open, port range, IP forwarding |
| `controlplane.yaml` | Control plane only: `br_netfilter` kernel module, load-balancer exclusion label, DHCP on `eno1` |
| `worker.yaml` | Workers only: `br_netfilter` kernel module, `bgp-policy: active` label |
| `winston.yaml` | `winston` only: bond0, disk selector, udev rules, NFS user volumes, extra firewall rule |
| `firewall-common.yaml` | Host firewall rules for every node |
| `firewall-controlplane.yaml` | Host firewall rules for control planes only (etcd, apid, trustd, API server) |
| `firewall-worker.yaml` | Host firewall rules for workers only (ingress, DNS, metrics, VPN egress) |

> talstomize does not template patches, so the firewall rules that used to be guarded by
> `{{ if .MachineConfig.MachineType }}` / `{{ if eq .Hostname "winston" }}` are split
> into one file per audience and wired up through `controlplanePatches`/`workerPatches`
> and `winston`'s own `patches`.

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

`talstomize build` decrypts `talsecret.sops.yaml` itself (it needs `sops` and the matching
PGP **private** key in the environment), so you normally never decrypt by hand.

## Network Tuning

The cluster includes comprehensive network performance tuning:

### sysctl Parameters

The `patches/network.yaml` file configures:

- **TCP Buffer Tuning** — Custom `tcp_rmem` and `tcp_wmem` values for high-throughput workloads
- **Socket Buffers** — 16 MB max receive/send buffers
- **Connection Backlog** — 65,535 listen backlog, 10,000 netdev backlog, 65,535 SYN backlog
- **BBR Congestion Control** — TCP BBR with Fair Queueing (FQ) qdisc
- **Connection Reuse** — `tcp_tw_reuse` enabled, reduced FIN timeout
- **Keepalive** — 10-minute idle, 30-second interval, 5 probes
- **TCP Fast Open** — Enabled (mode 3: both client and server)
- **Ephemeral Port Range** — Expanded to 1024–65535

### RPS/RFS

The `network-tuning` DaemonSet (inline manifest in `patches/cluster.yaml`) automatically:
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

The cluster is bootstrapped with GitOps and networking add-ons automatically via extra manifests defined in `patches/cluster.yaml`:

- **[Flux CD](https://fluxcd.io/)** — Installed from the latest release manifest. Manages all cluster workloads through GitOps reconciliation.
- **[Cilium](https://cilium.io/)** — kube-proxy replacement providing eBPF-based networking, observability, and security. The `cilium` namespace is pre-created at bootstrap.
- **[Gateway API](https://gateway-api.sigs.k8s.io/)** — Experimental Gateway API CRDs installed from the v1.6.1 release.

Since `cluster.proxy.disabled` is set to `true`, kube-proxy is not installed — Cilium handles all service networking.

## Contributing

Contributions are welcome and encouraged! Whether you're fixing a bug, improving documentation, or adding a new feature, please follow these guidelines:

1. **Fork the repository** and create a feature branch from `main`.
2. **Make your changes** — Keep them focused and well-documented.
3. **Test your configuration** by running `talstomize build` to ensure no errors.
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

*Built with [Talos Linux](https://www.talos.dev/), [talstomize](https://github.com/mirceanton/talstomize), and [SOPS](https://github.com/getsops/sops).*

## References
 - https://www.roosmaa.net/blog/2024/setting-up-zfs-on-talos/
