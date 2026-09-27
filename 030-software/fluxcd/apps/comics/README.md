# Comics

Comics hub: a `moleculer-ouistity` backend with separate api, graphql and marvel frontends, each behind its own route.

| | |
|---|---|
| Namespace | `comics` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://api.comics.${domain}
- https://apollo.comics.${domain}
- https://comics.${domain}

## Images

- `shokohsc/moleculer-ouistity:13415df`
- `busybox:1.38`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `api` | 100m / - | - / 256Mi |
| `comics` | 100m / - | - / 64Mi |
| `graphql` | 100m / - | - / 256Mi |
| `marvel` | 100m / - | - / 256Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`listener-set.yaml`](listener-set.yaml) | ListenerSet |
| [`api/deployment.yaml`](api/deployment.yaml) | Deployment |
| [`api/service.yaml`](api/service.yaml) | Service |
| [`api/http-route.yaml`](api/http-route.yaml) | HTTPRoute |
| [`graphql/deployment.yaml`](graphql/deployment.yaml) | Deployment |
| [`graphql/service.yaml`](graphql/service.yaml) | Service |
| [`graphql/http-route.yaml`](graphql/http-route.yaml) | HTTPRoute |
| [`marvel/deployment.yaml`](marvel/deployment.yaml) | Deployment |
| [`marvel/service.yaml`](marvel/service.yaml) | Service |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
