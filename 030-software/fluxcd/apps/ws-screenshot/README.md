# ws-screenshot

ws-screenshot, a URL-to-PNG screenshot service.

| | |
|---|---|
| Namespace | `ws-screenshot` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://ws-screenshot.${domain}

## Images

- `elestio/ws-screenshot.slim:1.2.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `ws-screenshot` | 100m / - | - / 512Mi |

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
