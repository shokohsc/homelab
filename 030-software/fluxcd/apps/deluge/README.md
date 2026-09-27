# Deluge

Deluge, the torrent client behind the `*arr` stack.

| | |
|---|---|
| Namespace | `deluge` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://deluge.${domain}

## Images

- `lscr.io/linuxserver/deluge:2.2.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `deluge` | 100m / 128Mi | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`cilium-network-policy.yaml`](cilium-network-policy.yaml) | CiliumNetworkPolicy |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${timezone}`.
