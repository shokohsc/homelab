# Tailscale

Tailscale, the cluster's tailnet connectivity.

| | |
|---|---|
| Namespace | `tailscale` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `ghcr.io/tailscale/tailscale:v1.102.5`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `tailscale` | 100m / 64Mi | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`rbac.yaml`](rbac.yaml) | Role, RoleBinding, ServiceAccount |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${cidr}`.
