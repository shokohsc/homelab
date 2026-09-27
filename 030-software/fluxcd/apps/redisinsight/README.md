# RedisInsight

RedisInsight, the web UI for the Valkey/Redis instances.

| | |
|---|---|
| Namespace | `redisinsight` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://redisinsight.${domain}

## Images

- `redislabs/redisinsight:3.8.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `redisinsight` | 100m / - | - / 256Mi |

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
