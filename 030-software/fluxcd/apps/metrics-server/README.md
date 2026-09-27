# metrics-server

metrics-server, installed from upstream manifests with patches so it works with Talos.

| | |
|---|---|
| Namespace | `metrics-server` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml | remote manifest |
