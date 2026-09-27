# Commander

Cloud Commander, a web file manager over the cluster's storage.

| | |
|---|---|
| Namespace | `commander` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `ghcr.io/coderaiser/cloudcmd:19.21.0-alpine`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `commander` | 100m / 64Mi | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`netpol.yaml`](netpol.yaml) | CiliumNetworkPolicy |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
