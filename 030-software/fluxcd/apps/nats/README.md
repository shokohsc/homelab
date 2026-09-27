# NATS

NATS, the message bus the moleculer services publish on.

| | |
|---|---|
| Namespace | `nats` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `nats:2.15.0-alpine`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `nats` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
