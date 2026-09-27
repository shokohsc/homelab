# Loki

Loki HelmRelease, the log store behind Grafana's Loki datasource.

| | |
|---|---|
| Namespace | `loki` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://loki.${domain}

## Helm

| Release | Chart | Version |
|---|---|---|
| `loki` | `oci://loki (OCIRepository)` | ^18.11.4 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `gateway` | 100m / - | - / 128Mi |
| `gateway.metrics` | 100m / - | - / 64Mi |
| `singleBinary` | 100m / - | - / 512Mi |
| `sidecar` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`loki.yaml`](loki.yaml) | OCIRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${interval}`.
