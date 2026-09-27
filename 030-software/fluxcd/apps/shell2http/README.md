# shell2http

shell2http as an HTTP-to-shell bridge, with curl/jq CronJobs and scripts in `scripts/`.

| | |
|---|---|
| Namespace | `shell2http` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://shell2http.${domain}

## Images

- `badouralix/curl-jq:alpine`
- `msoap/shell2http:1.17.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `webhook-trigger` | 100m / - | - / 64Mi |
| `shell2http` | 100m / - | - / 128Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`rbac.yaml`](rbac.yaml) | ServiceAccount, ClusterRoleBinding, ClusterRole |
| [`cronjob.yaml`](cronjob.yaml) | CronJob |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
