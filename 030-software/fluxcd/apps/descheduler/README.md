# Descheduler

The descheduler, run as a CronJob to rebalance evicted pods onto the Talos nodes.

| | |
|---|---|
| Namespace | `descheduler` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `registry.k8s.io/descheduler/descheduler:v0.36.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `descheduler` | 200m / - | - / 256Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`cronjob.yaml`](cronjob.yaml) | CronJob |
| [`rbac.yaml`](rbac.yaml) | ClusterRole, Role, ServiceAccount, ClusterRoleBinding, RoleBinding |
