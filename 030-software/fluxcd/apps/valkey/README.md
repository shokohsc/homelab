# Valkey

Valkey HelmRelease, the Redis-compatible cache.

| | |
|---|---|
| Namespace | `valkey` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Helm

| Release | Chart | Version |
|---|---|---|
| `valkey` | `valkey` | 0.12.0 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `release` | 100m / - | - / 512Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`valkey.yaml`](valkey.yaml) | HelmRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${interval}`.
