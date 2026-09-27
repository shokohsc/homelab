# syslog-ng

syslog-ng collector, fed by the Vector sidecars across the cluster.

| | |
|---|---|
| Namespace | `syslog` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `balabit/syslog-ng:4.12.0`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `syslog` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`routes.yaml`](routes.yaml) | TCPRoute |
| [`service.yaml`](service.yaml) | Service |
