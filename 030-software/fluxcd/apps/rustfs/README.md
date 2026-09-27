# RustFS

RustFS HelmRelease, an S3-compatible object store.

| | |
|---|---|
| Namespace | `rustfs` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://rustfs.${domain}

## Helm

| Release | Chart | Version |
|---|---|---|
| `rustfs` | `rustfs` | 1.0.0 |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `release` | 100m / - | - / 512Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`secret.yaml`](secret.yaml) | Secret |
| [`rustfs.yaml`](rustfs.yaml) | HelmRepository, HelmRelease |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${interval}`.
