# Renovate

Renovate as a CronJob: it opens the dependency update PRs from inside the cluster.

| | |
|---|---|
| Namespace | `renovate` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `ghcr.io/renovatebot/renovate:44.115.10`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `renovate` | 100m / 512Mi | - / 2048Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`cronjob.yaml`](cronjob.yaml) | CronJob |
| [`secret.yaml`](secret.yaml) | Secret |
