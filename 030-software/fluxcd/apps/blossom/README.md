# Blossom

Blossom, a server that turns a Jellyfin library into a streamed music source.

| | |
|---|---|
| Namespace | `blossom` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://blossom.${domain}

## Images

- `ghcr.io/hzrd149/blossom-server:v6.4`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `blossom` | 100m / 256Mi | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`secret.yaml`](secret.yaml) | Secret |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| configMap `config` | generated from `config/config.yml` |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
