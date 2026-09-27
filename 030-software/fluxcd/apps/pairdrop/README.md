# PairDrop

PairDrop, peer-to-peer file transfer between browsers.

| | |
|---|---|
| Namespace | `pairdrop` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://pairdrop.${domain}

## Images

- `lscr.io/linuxserver/pairdrop:1.11.2`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `pairdrop` | 100m / - | - / 64Mi |

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
