# VictoriaMetrics

VictoriaMetrics HelmRelease (single-node), the cluster's metrics store and Prometheus-compatible datasource.

| | |
|---|---|
| Namespace | `victoria-metrics` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://victoria-metrics.${domain}

## Helm

| Release | Chart | Version |
|---|---|---|
| `victoria-metrics` | `victoria-metrics-single` | 0.47.0 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `server` | 500m / - | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`victoria-metrics.yaml`](victoria-metrics.yaml) | HelmRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${interval}`.
