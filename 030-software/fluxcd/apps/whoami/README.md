# whoami

traefik/whoami, a deployment that echoes back its own request headers. Used to test routing end to end.

| | |
|---|---|
| Namespace | `whoami` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://whoami.${domain}

## Images

- `ghcr.io/traefik/whoami:v1.12`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `whoami` | 100m / - | - / 64Mi |

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
