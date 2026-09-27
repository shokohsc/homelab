# Samba

Samba, the SMB/CIFS file share.

| | |
|---|---|
| Namespace | `samba` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://samba.${domain}

## Images

- `dperson/samba:latest`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `samba` | 100m / 64Mi | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`routes.yaml`](routes.yaml) | TCPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
