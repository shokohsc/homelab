# Talos 1.13 Homelab

3 CP + 2 workers, DHCP, KubeSpan, Cilium CNI, VIP, custom trusted CA.

## Usage

```bash
# 1. Generate cluster secrets (auto-generated PKI)
./01-generate-secrets.sh

# 2. Generate machine configs with VIP and custom CA
export VIP_IP=10.42.20.5
export CA_CERT="$(cat /path/to/your-ca.crt)"
export K8S_ENDPOINT="cluster.example.com"
./generate-configs.sh

# 3. Apply to nodes
talosctl apply-config --insecure -n <dhcp-ip> -f controlplane.yaml

# 4. Bootstrap
talosctl bootstrap -n <cp1-ip>

# 5. Deploy Cilium
talosctl kubeconfig -n $VIP_IP
./deploy-cilium.sh
```

## Structure

| File | Purpose |
|------|---------|
| `01-generate-secrets.sh` | Generate `secrets.yaml` (cluster PKI) |
| `generate-configs.sh` | Generate `controlplane.yaml` + `worker.yaml` from patches |
| `deploy-cilium.sh` | Deploy Cilium via HelmChart manifest |
| `.env.example` | Template for required env vars |
| `patches/common.yaml` | certSANs, install disk, DHCP networking on `eno1` |
| `patches/network.yaml` | Network fine tuning |
| `patches/kubespan.yaml` | KubeSpanConfig with MTU 1420 |
| `patches/cluster-cni-none.yaml` | Disable kube-proxy (Cilium replaces) |
| `patches/ca-trust.yaml` | TrustedRootsConfig (`${CA_CERT}` env var injected) |
| `patches/controlplane.yaml` | `Layer2VIPConfig` with `${VIP_IP}` on `eno1` |
| `patches/worker.yaml` | Worker node taint (`mercy` role) |
| `cni/cilium.yaml` | Cilium 1.18 with kube-proxy replacement (KubeSpan compatible) |

## Env Vars

| Variable | Default | Description |
|----------|---------|-------------|
| `VIP_IP` | **(required)** | Virtual IP for Kubernetes API |
| `CA_CERT` | **(required)** | PEM CA certificate content for TrustedRootsConfig |
| `K8S_ENDPOINT` | **(required)** | kube api-server endpoint |
| `NETWORK_INTERFACE` | `eno1` | Node network interface |

## Notes

- **VIP**: Use `talosctl` with direct node IPs, not the VIP (VIP depends on etcd)
- **KubeSpan + Cilium**: Don't enable `bpf.masquerade` — incompatible
- **CA cert**: The `TrustedRootsConfig` patch adds your CA to the system trust store
- **Regenerating**: Same inputs + `--talos-version 1.13` = identical output

## Full regen command

```bash
CLUSTER_NAME=homelab
VIP_IP=10.42.20.5
K8S_ENDPOINT=kube.example.com
CA_CERT="$(cat /path/to/ca.pem)"

# Substitute VIP_IP into patches
awk -v ip="$VIP_IP" '{gsub(/\${VIP_IP}/, ip); print}' patches/common.yaml > patches/common.yaml.tmp
awk -v ip="$VIP_IP" '{gsub(/\${VIP_IP}/, ip); print}' patches/controlplane.yaml > patches/controlplane.yaml.tmp

# Generate CA trust patch inline
cat > patches/ca-trust.yaml.tmp << EOF
---
apiVersion: v1alpha1
kind: TrustedRootsConfig
name: custom-ca
certificates: |
$(printf '%s\n' "$CA_CERT" | awk '{print "    " $0}')
EOF

talosctl gen config "$CLUSTER_NAME" "https://${K8S_ENDPOINT}:6443" \
    --with-secrets secrets.yaml \
    --talos-version 1.13 \
    --kubernetes-version 1.36 \
    --config-patch @patches/common.yaml.tmp \
    --config-patch @patches/network.yaml \
    --config-patch @patches/kubespan.yaml \
    --config-patch @patches/cluster-cni-none.yaml \
    --config-patch @patches/ca-trust.yaml.tmp \
    --config-patch-control-plane @patches/controlplane.yaml.tmp \
    --force \
    --output .

rm -f patches/common.yaml.tmp patches/controlplane.yaml.tmp patches/ca-trust.yaml.tmp
```
