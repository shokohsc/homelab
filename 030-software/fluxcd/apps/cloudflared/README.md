# cloudflared

cloudflared tunnel connector, the cluster's ingress for public traffic.

| | |
|---|---|
| Namespace | `cloudflared` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `cloudflare/cloudflared:2026.9.3`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `cloudflared` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`secret.yaml`](secret.yaml) | Secret |
