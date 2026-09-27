# Whoogle

Whoogle, a metasearch front end for Google.

| | |
|---|---|
| Namespace | `whoogle` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Endpoints

- https://whoogle.${domain}

## Images

- `benbusby/whoogle-search:1.2.4`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `whoogle` | 100m / 64Mi | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`.

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- whoogle` entry and sync to deploy.
