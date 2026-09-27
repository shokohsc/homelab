# KubeOpenCode

KubeOpenCode HelmRelease: the AI agent controller that runs tasks against this cluster.

| | |
|---|---|
| Namespace | `kubeopencode` |
| Flux Kustomization | `infrastructure` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://kubeopencode.${domain}

## Helm

| Release | Chart | Version |
|---|---|---|
| `kubeopencode` | `oci://kubeopencode (OCIRepository)` | ^v0.1.9 |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`kubeopencode.yaml`](kubeopencode.yaml) | OCIRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${interval}`.
