# Vaultwarden

Vaultwarden, a Bitwarden-compatible password manager behind Pocket ID.

| | |
|---|---|
| Namespace | `vaultwarden` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://vaultwarden.${domain}

## Images

- `node:alpine`
- `ghcr.io/dani-garcia/vaultwarden:1.37.3`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `vaultwarden` | 100m / - | - / 512Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
