# IPTVnator

IPTV manager with a Go backend and a busybox-served frontend.

| | |
|---|---|
| Namespace | `iptvnator` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://api.iptvnator.${domain}
- https://iptvnator.${domain}

## Images

- `4gray/iptvnator-backend:latest`
- `busybox:1.38`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `iptvnator-backend` | 100m / - | - / 256Mi |
| `iptvnator` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`listener-set.yaml`](listener-set.yaml) | ListenerSet |
| [`frontend/deployment.yaml`](frontend/deployment.yaml) | Deployment |
| [`frontend/service.yaml`](frontend/service.yaml) | Service |
| [`frontend/http-route.yaml`](frontend/http-route.yaml) | HTTPRoute |
| [`backend/deployment.yaml`](backend/deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`backend/service.yaml`](backend/service.yaml) | Service |
| [`backend/http-route.yaml`](backend/http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
