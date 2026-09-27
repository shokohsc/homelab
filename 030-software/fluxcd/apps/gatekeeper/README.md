# Gatekeeper

Gatekeeper constraint templates and instances for this cluster's admission rules.

| | |
|---|---|
| Namespace | `gatekeeper-system` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Manifests

| File | Contents |
|---|---|
| [`config.yaml`](config.yaml) | Config |
| [`constraints.yaml`](constraints.yaml) | K8sContainerLimits, K8sPSPHostFilesystem, K8sPSPHostNamespace, K8sPSPPrivilegedContainer, K8sPSPAllowPrivilegeEscalationContainer, K8sPSPReadOnlyRootFilesystem, K8sPSPCapabilities, K8sPSPAllowedUsers, K8sDisallowAnonymous, K8sPSPVolumeTypes, K8sPSPSeccompV2 |
