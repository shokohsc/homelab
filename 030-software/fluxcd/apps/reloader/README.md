# Reloader

Reloader, watches ConfigMaps and Secrets and restarts the pods that mount them.

| | |
|---|---|
| Namespace | `reloader` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Helm

| Release | Chart | Version |
|---|---|---|
| `reloader` | `reloader` | 2.2.17 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `reloader.deployment` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`reloader.yaml`](reloader.yaml) | HelmRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${interval}`.
