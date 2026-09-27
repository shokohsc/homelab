# VPN egress gateway

vpn-egress-gateway plus its mutating webhook: pins labelled workloads behind an egress-only route so their traffic leaves through the VPN.

| | |
|---|---|
| Namespace | `vpn-egress-gateway` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `ghcr.io/shokohsc/gateway:3c96fd6`
- `ghcr.io/shokohsc/vpn-egress-gateway:3c96fd6`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `gateway` | 100m / - | - / 64Mi |
| `webhook` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`mutatingwebhook.yaml`](mutatingwebhook.yaml) | MutatingWebhookConfiguration |
| [`certificate.yaml`](certificate.yaml) | Certificate |
| [`issuer.yaml`](issuer.yaml) | Issuer |
| [`cilium-network-policy.yaml`](cilium-network-policy.yaml) | CiliumNetworkPolicy |
