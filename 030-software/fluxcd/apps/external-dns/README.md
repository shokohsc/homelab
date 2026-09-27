# external-dns

external-dns HelmRelease: keeps the wildcard DNS records in sync with the HTTPRoutes and TCPRoutes in the cluster.

| | |
|---|---|
| Namespace | `external-dns` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Helm

| Release | Chart | Version |
|---|---|---|
| `external-dns` | `external-dns` | 1.22.0 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `release` | 100m / - | - / 64Mi |
| `provider.webhook` | - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`external-dns.yaml`](external-dns.yaml) | HelmRepository, HelmRelease |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${interval}`.
