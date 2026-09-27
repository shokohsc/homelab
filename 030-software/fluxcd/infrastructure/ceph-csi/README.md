# ceph-csi

ceph-csi HelmRelease, the CSI driver backing the Ceph RBD storage classes.

| | |
|---|---|
| Namespace | `ceph-csi` |
| Flux Kustomization | `infrastructure` |
| Reconciled | yes, from `../kustomization.yaml` |

## Helm

| Release | Chart | Version |
|---|---|---|
| `ceph-csi` | `ceph-csi-rbd` | 3.18.0 |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`configmap.yaml`](configmap.yaml) | ConfigMap |
| [`secret.yaml`](secret.yaml) | Secret |
| [`ceph-csi.yaml`](ceph-csi.yaml) | HelmRepository, HelmRelease |

## Substitutions

Flux `postBuild` values used here: `${interval}`.
