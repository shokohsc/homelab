# Byparr

Byparr, a FlareSolverr-compatible proxy that fetches pages JavaScript protection would otherwise block.

| | |
|---|---|
| Namespace | `byparr` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Images

- `ghcr.io/thephaseless/byparr:3.0.4`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `byparr` | 100m / 64Mi | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`service.yaml`](service.yaml) | Service |

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- byparr` entry and sync to deploy.
