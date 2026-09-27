# Proxmox

caddy reverse proxy in front of the Proxmox VE API, with its own certificate and route.

| | |
|---|---|
| Namespace | `proxmox` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://proxmox.${domain}

## Images

- `caddy:2.11.4-alpine`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `caddy` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| configMap `config` | generated from `config/Caddyfile` |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
