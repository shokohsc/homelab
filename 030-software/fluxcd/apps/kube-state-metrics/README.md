# kube-state-metrics

kube-state-metrics HelmRelease, feeding object state into Prometheus.

| | |
|---|---|
| Namespace | `kube-state-metrics` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Helm

| Release | Chart | Version |
|---|---|---|
| `kube-state-metrics` | `oci://kube-state-metrics (OCIRepository)` | ^v7.4.0 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `release` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`kube-state-metrics.yaml`](kube-state-metrics.yaml) | OCIRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${interval}`.
