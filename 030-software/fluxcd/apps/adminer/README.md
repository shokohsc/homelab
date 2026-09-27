# Adminer

Adminer, a single-container web UI for poking at the cluster's databases.

| | |
|---|---|
| Namespace | `adminer` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://adminer.${domain}

## Images

- `adminer:6.1.1-standalone`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `adminer` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
