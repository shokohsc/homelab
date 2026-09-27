# NFS downloads

NFS client mounting the Proxmox downloads share into the `downloads` namespace.

| | |
|---|---|
| Namespace | `nfs-downloads` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Images

- `itsthenetwork/nfs-server-alpine:latest`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `nfs-server-alpine` | 100m / 64Mi | - / 1024Mi |

## Manifests

| File | Contents |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`poddisruptionbudget.yaml`](poddisruptionbudget.yaml) | PodDisruptionBudget |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |
| [`service.yaml`](service.yaml) | Service |
