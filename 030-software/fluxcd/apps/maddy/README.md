# Maddy

Mail server (maddy) fronted by caddy, plus an offsite docker-volume-backup sidecar.

| | |
|---|---|
| Namespace | `maddy` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://maddy.${domain}

## Images

- `offen/docker-volume-backup:v2.49.1@sha256:e1da571e739d73f633f19e7a9f324007907089ffd80b3b7a1d71de5b87f80d77`
- `golang:1.27.1-alpine`
- `foxcpp/maddy:0.9.5`
- `caddy:2.11.4-alpine`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `maddy` | 100m / 64Mi | - / 1024Mi |
| `caddy` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`certificate.yaml`](certificate.yaml) | Certificate |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`routes.yaml`](routes.yaml) | TCPRoute |
| [`rbac.yaml`](rbac.yaml) | ServiceAccount, RoleBinding, Role |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${publicDomain}`.
