# Alloy

Grafana Alloy, the agent that tails logs and scrapes metrics for Loki and VictoriaMetrics.

| | |
|---|---|
| Namespace | `alloy` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://alloy.${domain}

## Helm

| Release | Chart | Version |
|---|---|---|
| `alloy` | `alloy` | 1.12.1 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `alloy` | 100m / - | - / 256Mi |
| `configReloader` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`alloy.yaml`](alloy.yaml) | HelmRepository, HelmRelease |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${interval}`.
