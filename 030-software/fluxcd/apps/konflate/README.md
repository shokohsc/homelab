# Konflate

Konflate: renders this repo's Flux manifests with values from the GitHub API, so the cluster can inspect its own desired state.

| | |
|---|---|
| Namespace | `konflate` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://konflate.${domain}

## Images

- `ghcr.io/home-operations/konflate:0.6.4`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `konflate` | 100m / 64Mi | - / 1024Mi |

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
