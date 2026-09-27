# FerretDB

FerretDB, a MongoDB-compatible API on top of CloudNativePG.

| | |
|---|---|
| Namespace | `ferretdb` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Images

- `ghcr.io/ferretdb/ferretdb:2.7.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `ferretdb` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`secret.yaml`](secret.yaml) | Secret |
| [`service.yaml`](service.yaml) | Service |

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- ferretdb` entry and sync to deploy.
