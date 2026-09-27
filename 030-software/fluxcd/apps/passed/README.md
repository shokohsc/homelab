# Passed

Personal `shokohsc/passed` service; the manifests here are all the repo carries.

| | |
|---|---|
| Namespace | `passed` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://passed.${domain}

## Images

- `shokohsc/passed:latest`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `passed` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
