# Miniflux

Miniflux, a feed reader behind Pocket ID.

| | |
|---|---|
| Namespace | `miniflux` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://miniflux.${domain}

## Images

- `miniflux/miniflux:2.3.3`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `miniflux` | 100m / 64Mi | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
