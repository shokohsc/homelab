#!/usr/bin/env bash
set -euo pipefail

echo "=== Deploying Cilium CNI ==="
echo "Using default configuration compatible with KubeSpan"
echo ""

kubectl apply -f cni/cilium.yaml

echo ""
echo "Waiting for Cilium pods to be ready..."
kubectl -n kube-system rollout status daemonset/cilium --timeout=300s

echo ""
echo "Cilium deployed successfully."
echo "Verify with: kubectl -n kube-system get pods -l k8s-app=cilium"
