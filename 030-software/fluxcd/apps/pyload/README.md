# pyLoad

pyLoad, the download manager.

| | |
|---|---|
| Namespace | `pyload` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://pyload.${domain}

## Images

- `ghcr.io/home-operations/pyload-ng:0.5.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `pyload` | 100m / - | - / 128Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
