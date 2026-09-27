# Grist

Grist, spreadsheet database with per-document access control.

| | |
|---|---|
| Namespace | `grist` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://grist.${domain}

## Images

- `gristlabs/grist:1.7.19`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `grist` | 200m / - | - / 256Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
