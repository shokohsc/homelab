# Code Server

code-server, VS Code in the browser with the workspace mounted.

| | |
|---|---|
| Namespace | `code-server` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://code-server.${domain}

## Images

- `ghcr.io/coder/code-server:4.138.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `code-server` | 100m / 64Mi | - / 4096Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`rbac.yaml`](rbac.yaml) | ServiceAccount, ClusterRoleBinding |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
