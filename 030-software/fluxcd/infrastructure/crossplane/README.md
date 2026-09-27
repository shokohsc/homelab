# Crossplane

Provider configuration for the Proxmox Crossplane provider family.

| | |
|---|---|
| Namespace | `crossplane-system` |
| Flux Kustomization | `infrastructure` |
| Reconciled | yes, from `../kustomization.yaml` |

## Manifests

| File | Contents |
|---|---|
| [`proxmoxidentity.yaml`](proxmoxidentity.yaml) | ProxmoxIdentity |

## Substitutions

Flux `postBuild` values used here: `${publicDomain}`.
