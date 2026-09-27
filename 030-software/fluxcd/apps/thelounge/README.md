# The Lounge

The Lounge, a web IRC client for the WeeChat instance.

| | |
|---|---|
| Namespace | `thelounge` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Endpoints

- https://thelounge.${domain}

## Images

- `ghcr.io/thelounge/thelounge:4.5.2`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `thelounge` | 100m / - | - / 512Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`service.yaml`](service.yaml) | Service |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`.

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- thelounge` entry and sync to deploy.
