# Swing Music

Swing Music, a self-hosted music streaming server.

| | |
|---|---|
| Namespace | `swingmusic` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://swingmusic.${domain}

## Images

- `ghcr.io/swingmx/swingmusic:v3.0.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `swingmusic` | 100m / 64Mi | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
