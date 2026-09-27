# Plex

Plex Media Server with a Vector sidecar shipping its logs to Loki.

| | |
|---|---|
| Namespace | `plex` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://plex.${domain}

## Images

- `plexinc/pms-docker:1.43.4.10903-e5521bd8c`
- `timberio/vector:0.58.0-alpine`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `plex` | 100m / 2048Mi | - / 4096Mi |
| `vector` | 100m / - | - / 128Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`secret.yaml`](secret.yaml) | Secret |
| [`routes.yaml`](routes.yaml) | HTTPRoute, TCPRoute, UDPRoute |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |

## Substitutions

Flux `postBuild` values used here: `${cidr}`, `${domain}`, `${kubeServicesCidr}`, `${timezone}`, `${vip}`.
