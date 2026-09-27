# Weechat

WeeChat in a container with a glowing-bear web client in the same pod.

| | |
|---|---|
| Namespace | `weechat` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://irc.${domain}
- https://weechat.${domain}

## Images

- `weechat/weechat:4.10.1-alpine-slim`
- `j33r/glowing-bear:latest`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `weechat` | 100m / - | - / 128Mi |
| `glowing-bear` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${timezone}`.
