# Browserless

browserless, headless Chrome as a service for the other apps to drive.

| | |
|---|---|
| Namespace | `browserless` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://browserless.${domain}

## Images

- `ghcr.io/browserless/chromium:v2.56.7`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `browserless` | 100m / 512Mi | - / 4096Mi |

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
