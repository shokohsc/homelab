# VictoriaLogs

VictoriaLogs HelmRelease, the second log store.

| | |
|---|---|
| Namespace | `victoria-logs` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Endpoints

- https://victoria-logs.${domain}

## Helm

| Release | Chart | Version |
|---|---|---|
| `victoria-logs` | `victoria-logs-single` | 0.13.9 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `server` | 500m / - | - / 512Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`victoria-logs.yaml`](victoria-logs.yaml) | HelmRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${interval}`.

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- victoria-logs` entry and sync to deploy.
