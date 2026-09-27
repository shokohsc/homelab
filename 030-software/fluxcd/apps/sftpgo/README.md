# SFTPGo

SFTPGo, SFTP/FTP/HTTP file access over the cluster's storage.

| | |
|---|---|
| Namespace | `sftpgo` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://sftpgo.${domain}

## Images

- `ghcr.io/drakkan/sftpgo:v2.7.6-distroless-slim`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `sftpgo` | 100m / 64Mi | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`routes.yaml`](routes.yaml) | TCPRoute |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
