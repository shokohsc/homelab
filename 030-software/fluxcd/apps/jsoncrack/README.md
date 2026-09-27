# JSONCrack

JSONCrack, the JSON visualiser (this repo tracks a fork with a shokohsc build).

| | |
|---|---|
| Namespace | `jsoncrack` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://jsoncrack.${domain}

## Images

- `shokohsc/jsoncrack:latest`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `jsoncrack` | 100m / - | - / 64Mi |

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
