# Blocky

blocky, a DNS proxy with ad-blocking and per-client filtering.

| | |
|---|---|
| Namespace | `blocky` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Endpoints

- https://blocky.${domain}

## Images

- `ghcr.io/0xerr0r/blocky:v0.35.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `blocky` | 100m / 64Mi | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`service.yaml`](service.yaml) | Service |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${subnet}`, `${timezone}`.

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- blocky` entry and sync to deploy.
