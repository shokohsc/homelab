# Prowlarr

Prowlarr, the indexer manager feeding the `*arr` apps.

| | |
|---|---|
| Namespace | `prowlarr` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://prowlarr.${domain}

## Images

- `ghcr.io/home-operations/prowlarr:2.6.5`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `prowlarr` | 100m / - | - / 256Mi |

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
