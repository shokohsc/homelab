# Radarr

Radarr, for films.

| | |
|---|---|
| Namespace | `radarr` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://radarr.${domain}

## Images

- `ghcr.io/home-operations/radarr:6.4.4`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `radarr` | 100m / 256Mi | - / 2048Mi |

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

Flux `postBuild` values used here: `${domain}`, `${timezone}`.
