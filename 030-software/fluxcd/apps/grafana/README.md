# Grafana

Grafana, wired to VictoriaMetrics, Loki and the sidekick API as datasources.

| | |
|---|---|
| Namespace | `grafana` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://grafana.${domain}

## Helm

| Release | Chart | Version |
|---|---|---|
| `grafana` | `grafana` | 13.2.5 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `downloadDashboards` | 100m / - | - / 64Mi |
| `initChownData` | 100m / - | - / 64Mi |
| `release` | 100m / - | - / 1024Mi |
| `sidecar` | 100m / 1024Mi | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`grafana.yaml`](grafana.yaml) | HelmRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${interval}`.
