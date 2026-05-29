# Homelab

## Talos configuration

## FluxCD

https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html

https://fluxcd.io/flux/guides/mozilla-sops/#prerequisites

After Terraform creates the BGP peer on MikroTik, you'll need to apply this to cluster:
# cilium-bgp.yaml
apiVersion: "cilium.io/v2alpha1"
kind: CiliumBGPClusterConfig
metadata:
  name: cilium-bgp
spec:
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/control-plane: ""
  bgpInstances:
    - name: "cilium-bgp"
      localASN: 65000
      peers:
        - name: "mikrotik-peer"
          peerASN: 65001
          peerAddress: "10.42.0.1/32"
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: production-pool
spec:
  blocks:
    - cidr: "10.42.50.0/24"