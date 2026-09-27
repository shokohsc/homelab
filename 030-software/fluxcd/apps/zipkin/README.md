# Zipkin

Zipkin, the trace UI, with a Vector sidecar feeding it from the cluster logs.

| | |
|---|---|
| Namespace | `zipkin` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `timberio/vector:0.58.0-alpine`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `vector` | 100m / - | - / 256Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`service.yaml`](service.yaml) | Service |
