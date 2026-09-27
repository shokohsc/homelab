# http-echo

http-https-echo, a request-inspection endpoint for testing ingress and TLS termination.

| | |
|---|---|
| Namespace | `http-echo` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://http-echo.${domain}

## Images

- `mendhak/http-https-echo:42`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `http-echo` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
