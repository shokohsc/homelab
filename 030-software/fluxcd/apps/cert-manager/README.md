# cert-manager

The cluster's own certificate resources: issuers, wildcard bundles and the certificates apps attach to their routes.

| | |
|---|---|
| Namespace | `cert-manager` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Manifests

| File | Contents |
|---|---|
| [`secret.yaml`](secret.yaml) | Secret |
| [`issuer.yaml`](issuer.yaml) | ClusterIssuer |
| [`bundle.yaml`](bundle.yaml) | Bundle |

## Substitutions

Flux `postBuild` values used here: `${publicDomain}`.
