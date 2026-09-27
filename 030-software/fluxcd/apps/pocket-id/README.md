# Pocket ID

Pocket ID, the single sign-on provider the other apps authenticate against.

| | |
|---|---|
| Namespace | `pocket-id` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://pocket-id.${domain}

## Images

- `ghcr.io/pocket-id/pocket-id:v2`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `pocket-id` | 100m / - | - / 512Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`secret.yaml`](secret.yaml) | Secret |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
