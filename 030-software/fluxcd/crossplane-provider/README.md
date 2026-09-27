# Crossplane Provider

Crossplane provider family (Proxmox), the function/runtime configuration and the provider secret.

| | |
|---|---|
| Namespace | `crossplane-system` |
| Flux Kustomization | `crossplane-provider` |

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `package-runtime` | 100m / - | - / 512Mi |

## Manifests

| File | Contents |
|---|---|
| [`secret.yaml`](secret.yaml) | Secret |
| [`deployment-runtime-config.yaml`](deployment-runtime-config.yaml) | DeploymentRuntimeConfig |
| [`provider.yaml`](provider.yaml) | Provider |
| [`functions.yaml`](functions.yaml) | Function |
