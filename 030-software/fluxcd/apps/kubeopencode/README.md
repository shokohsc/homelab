# KubeOpenCode

KubeOpenCode's own manifests in the `workspace` namespace: agent, RBAC, config and the bundled skills.

| | |
|---|---|
| Namespace | `workspace` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`secret.yaml`](secret.yaml) | Secret |
| [`rbac.yaml`](rbac.yaml) | ServiceAccount, ClusterRole, ClusterRoleBinding |
| [`agent-templates/main.yaml`](agent-templates/main.yaml) | AgentTemplate |
| [`agent-templates/homelab.yaml`](agent-templates/homelab.yaml) | AgentTemplate |
| [`agent-templates/talos-proxmox-autoscaler.yaml`](agent-templates/talos-proxmox-autoscaler.yaml) | AgentTemplate |
| [`agent.yaml`](agent.yaml) | Agent |
| [`cilium-network-policy.yaml`](cilium-network-policy.yaml) | CiliumNetworkPolicy |
