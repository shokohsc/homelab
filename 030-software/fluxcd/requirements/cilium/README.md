# Cilium

Cilium cluster resources: BGP peering with the MikroTik router and the `cilium` Gateway every app hangs its HTTPRoute off.

| | |
|---|---|
| Namespace | `cilium` |
| Flux Kustomization | `requirements` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://hubble.${domain}

## Manifests

| File | Contents |
|---|---|
| [`bgp.yaml`](bgp.yaml) | CiliumBGPAdvertisement, CiliumBGPPeerConfig, CiliumBGPClusterConfig, CiliumLoadBalancerIPPool |
| [`gateway.yaml`](gateway.yaml) | Gateway |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${subnet}`, `${talosSubnet}`, `${vip}`.
