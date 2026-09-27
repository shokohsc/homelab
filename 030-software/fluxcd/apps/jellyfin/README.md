# Jellyfin

Jellyfin media server, with HTTPRoute for the web UI plus TCPRoute and UDPRoute for discovery and DLNA.

| | |
|---|---|
| Namespace | `jellyfin` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://jellyfin.${domain}

## Images

- `ghcr.io/jellyfin/jellyfin:10.11.11`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `jellyfin` | 100m / 1024Mi | - / 4096Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`routes.yaml`](routes.yaml) | TCPRoute, UDPRoute |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${timezone}`.
