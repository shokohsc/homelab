# Crossplane

Crossplane 2.4.2, the basis for the Proxmox infrastructure compositions.

| | |
|---|---|
| Namespace | `crossplane-system` |
| Flux Kustomization | `requirements` |
| Reconciled | yes, from `../kustomization.yaml` |

## Helm

| Release | Chart | Version |
|---|---|---|
| `crossplane` | `crossplane` | 2.4.2 |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`crossplane.yaml`](crossplane.yaml) | HelmRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${interval}`.
