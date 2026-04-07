# Homelab Project

## Overview
This project documents the setup and management of my homelab, which is a Kubernetes cluster deployed using GitOps with FluxCD and Talos Linux. The homelab serves as a platform for various applications, development, and learning purposes.

## Architecture
The homelab consists of the following components:

### PKI Infrastructure
- Offline root CA and intermediate CA(s) for certificate management.
- Keys and certificates are stored on a YubiKey 5C NFC.
- Keys are also backed up to a USB drive and encrypted with a GPG key.

### Networking

### Kubernetes Cluster

### Proxmox Nodes

## Deployment
The Kubernetes cluster is deployed using GitOps with FluxCD and Talos Linux. The configuration files are stored in a Git repository, and FluxCD is responsible for applying the changes to the cluster.

## Usage
The homelab is used for various purposes, including:
- Running applications and services.
- Development and testing environments.
- Learning and experimenting with new technologies.

## Future Plans
- Scale out additional worker VMs as needed.
- Explore and implement new technologies and tools.
- Improve the overall performance and reliability of the homelab.

## Visualization
  - cd visualization && npx vite --host 0.0.0.0 --port 8080
