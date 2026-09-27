# FlareSolverr

FlareSolverr, used to fetch pages behind Cloudflare.

| | |
|---|---|
| Namespace | `flaresolverr` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Images

- `ghcr.io/flaresolverr/flaresolverr:v3.5.2`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `flaresolverr` | 100m / - | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`service.yaml`](service.yaml) | Service |

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- flaresolverr` entry and sync to deploy.
