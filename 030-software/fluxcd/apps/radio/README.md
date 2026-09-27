# Radio

Home radio: a `radio-server` API, a busybox UI and a genji sidecar that publishes the track list, exposed on a ListenerSet so the UI and API are both on 443.

| | |
|---|---|
| Namespace | `radio` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://radio.${domain}
- https://api.radio.${domain}

## Images

- `ghcr.io/shokohsc/radio-server:sha-1ab71f5`
- `busybox:1.38`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `radio-server` | 100m / 64Mi | - / 1024Mi |
| `radio-ui` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`listener-set.yaml`](listener-set.yaml) | ListenerSet |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
