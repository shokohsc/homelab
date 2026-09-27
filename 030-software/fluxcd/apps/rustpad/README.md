# Rustpad

Rustpad, collaborative code editing in the browser.

| | |
|---|---|
| Namespace | `rustpad` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://rustpad.${domain}

## Images

- `ekzhang/rustpad:latest`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `rustpad` | 100m / - | - / 64Mi |

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
