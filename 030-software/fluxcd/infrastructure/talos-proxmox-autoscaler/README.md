# Talos Proxmox Autoscaler

Autoscaler for Talos VMs running on Proxmox, plus the provider config it needs.

| | |
|---|---|
| Namespace | `talos-proxmox-autoscaler` |
| Flux Kustomization | `infrastructure` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `ghcr.io/shokohsc/talos-proxmox-autoscaler:3ef790d`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `talos-proxmox-autoscaler` | 100m / - | - / 128Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`provider-config.yaml`](provider-config.yaml) | ProviderConfig |
| [`proxmoxidentity.yaml`](proxmoxidentity.yaml) | ProxmoxIdentity |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`configmap.yaml`](configmap.yaml) | ConfigMap |
| [`rbac.yaml`](rbac.yaml) | ServiceAccount, ClusterRole, ClusterRoleBinding |
| [`secret.yaml`](secret.yaml) | Secret |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${publicDomain}`.
