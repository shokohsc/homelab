# Motrix

Motrix, a GUI download manager.

| | |
|---|---|
| Namespace | `motrix` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Endpoints

- https://motrix.${domain}

## Images

- `ghcr.io/agalwood/motrix-server:2.0.0-beta.40`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `motrix` | 100m / 64Mi | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`service.yaml`](service.yaml) | Service |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${domain}`.

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- motrix` entry and sync to deploy.
