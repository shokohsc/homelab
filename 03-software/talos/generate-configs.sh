#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="homelab"
K8S_ENDPOINT="https://${K8S_ENDPOINT}:6443"
NETWORK_INTERFACE="${NETWORK_INTERFACE:-eno1}"

if [ ! -f "secrets.yaml" ]; then
    echo "ERROR: secrets.yaml not found. Run 01-generate-secrets.sh first."
    exit 1
fi

: "${VIP_IP:?VIP_IP not set. Usage: VIP_IP=10.42.20.5 ./generate-configs.sh}"
: "${CA_CERT:?CA_CERT not set. Export your CA certificate as a single-line base64 body or full PEM.}"

echo "=== Generating machine configurations for Talos 1.13 ==="
echo "Cluster: $CLUSTER_NAME"
echo "Endpoint: $K8S_ENDPOINT"
echo "VIP: $VIP_IP"
echo "Interface: $NETWORK_INTERFACE"
echo ""

awk -v ip="$VIP_IP" '{gsub(/\${VIP_IP}/, ip); print}' patches/common.yaml > patches/common.yaml.tmp
awk -v ip="$VIP_IP" '{gsub(/\${VIP_IP}/, ip); print}' patches/controlplane.yaml > patches/controlplane.yaml.tmp

cat > patches/ca-trust.yaml.tmp << EOF
---
apiVersion: v1alpha1
kind: TrustedRootsConfig
name: custom-ca
certificates: |
$(printf '%s\n' "$CA_CERT" | awk '{print "    " $0}')
EOF

talosctl gen config "$CLUSTER_NAME" "$K8S_ENDPOINT" \
    --with-secrets secrets.yaml \
    --talos-version "1.13" \
    --kubernetes-version "1.36" \
    --config-patch @patches/common.yaml.tmp \
    --config-patch @patches/network.yaml \
    --config-patch @patches/kubespan.yaml \
    --config-patch @patches/cluster-cni-none.yaml \
    --config-patch @patches/ca-trust.yaml.tmp \
    --config-patch-control-plane @patches/controlplane.yaml.tmp \
    --force \
    --output .

rm -f patches/common.yaml.tmp \
      patches/controle-plane.yaml.tmp \
      patches/ca-trust.yaml.tmp

echo ""
echo "=== Generated files ==="
ls -la *.yaml

echo ""
echo "=== Apply to nodes ==="
echo "  talosctl apply-config --insecure -n <node-ip> --file controlplane.yaml"
echo ""
echo "=== Bootstrap ==="
echo "  talosctl bootstrap -n <cp1-ip>"
echo ""
echo "=== Get kubeconfig ==="
echo "  talosctl kubeconfig -n $VIP_IP"
echo ""
echo "=== Deploy Cilium ==="
echo "  ./deploy-cilium.sh"
