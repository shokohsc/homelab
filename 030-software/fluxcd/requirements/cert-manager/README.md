# cert-manager

cert-manager and trust-manager, installed by HelmRelease. Everything else in the cluster gets its certificates from here.

| | |
|---|---|
| Namespace | `cert-manager` |
| Flux Kustomization | `requirements` |
| Reconciled | yes, from `../kustomization.yaml` |

## Helm

| Release | Chart | Version |
|---|---|---|
| `cert-manager` | `oci://cert-manager (OCIRepository)` | ^v1.20.2 |
| `trust-manager` | `oci://trust-manager (OCIRepository)` | ^0.22.1 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `release` | 100m / - | - / 512Mi |
| `webhook` | 100m / - | - / 512Mi |
| `cainjector` | 100m / - | - / 512Mi |
| `release` | - | - / 128Mi |
| `defaultPackage` | - | - / 128Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`cert-manager.yaml`](cert-manager.yaml) | OCIRepository, HelmRelease |
| [`trust-manager.yaml`](trust-manager.yaml) | OCIRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${interval}`.
