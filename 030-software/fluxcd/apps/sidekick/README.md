# Sidekick

Moleculer-based home automation: the `api` service (configured by a `common-env` ConfigMap), a `vpn` component, and disabled `cmangos`, `email` and `kubernetesevents` modules. It talks to the rest of the stack over NATS.

| | |
|---|---|
| Namespace | `sidekick` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://sidekick.${domain}

## Images

- `shokohsc/moleculer-sidekick:a628e77`
- `postgres:18.6`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `api` | 100m / - | - / 512Mi |
| `cmangos` | 100m / - | - / 256Mi |
| `email` | 100m / - | - / 256Mi |
| `postgres` | 100m / - | - / 64Mi |
| `kubernetesevents` | 100m / - | - / 256Mi |
| `vpn` | 100m / - | - / 128Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`api/deployment.yaml`](api/deployment.yaml) | Deployment |
| [`api/service.yaml`](api/service.yaml) | Service |
| [`api/http-route.yaml`](api/http-route.yaml) | HTTPRoute |
| [`api/rbac.yaml`](api/rbac.yaml) | ServiceAccount, ClusterRoleBinding, ClusterRole |
| [`vpn/deployment.yaml`](vpn/deployment.yaml) | Deployment |
| [`vpn/service.yaml`](vpn/service.yaml) | Service |
| [`vpn/secret.yaml`](vpn/secret.yaml) | Secret |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| configMap `common-env` | generated from `config/common-env` |
| configMap `config` | generated from `config/nats.conf` |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
