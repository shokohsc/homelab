# VictoriaLogs collector

VictoriaLogs collector HelmRelease, the agent that ships logs into VictoriaLogs.

| | |
|---|---|
| Namespace | `victoria-logs-collector` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Helm

| Release | Chart | Version |
|---|---|---|
| `victoria-logs-collector` | `victoria-logs-collector` | 0.3.7 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `release` | 500m / 64Mi | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`victoria-logs-collector.yaml`](victoria-logs-collector.yaml) | HelmRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${interval}`.

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- victoria-logs-collector` entry and sync to deploy.
