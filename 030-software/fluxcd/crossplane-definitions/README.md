# Crossplane Definitions

Crossplane XRDs and compositions: the `ProxmoxIdentity`, `ProxmoxVMTemplate` and `ProxmoxCEPHPool` APIs the cluster automates with.

| | |
|---|---|
| Namespace | `crossplane-system` |
| Flux Kustomization | `crossplane-definitions` |

## Manifests

| File | Contents |
|---|---|
| [`provider-config.yaml`](provider-config.yaml) | ProviderConfig |
| [`xrds/proxmoxidentity.yaml`](xrds/proxmoxidentity.yaml) | CompositeResourceDefinition |
| [`xrds/proxmoxcephpool.yaml`](xrds/proxmoxcephpool.yaml) | CompositeResourceDefinition |
| [`xrds/proxmoxvmtemplate.yaml`](xrds/proxmoxvmtemplate.yaml) | CompositeResourceDefinition |
| [`compositions/proxmoxidentity.yaml`](compositions/proxmoxidentity.yaml) | Composition |
| [`compositions/proxmoxcephpool.yaml`](compositions/proxmoxcephpool.yaml) | Composition |
| [`compositions/proxmoxvmtemplate.yaml`](compositions/proxmoxvmtemplate.yaml) | Composition |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${publicDomain}`.
