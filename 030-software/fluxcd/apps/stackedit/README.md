# Stackedit

StackEdit, an in-browser Markdown editor.

| | |
|---|---|
| Namespace | `stackedit` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://stackedit.${domain}

## Images

- `benweet/stackedit:v5.15.4`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `stackedit` | 100m / - | - / 128Mi |

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
