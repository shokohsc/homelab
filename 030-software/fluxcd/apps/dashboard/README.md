# Dashboard

The cluster landing page (busybox). Its links come from the `dashboard.${domain}/*` annotations on the HTTPRoutes.

| | |
|---|---|
| Namespace | `dashboard` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://dashboard.${domain}

## Images

- `busybox:1.38`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `dashboard` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`service.yaml`](service.yaml) | Service |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
