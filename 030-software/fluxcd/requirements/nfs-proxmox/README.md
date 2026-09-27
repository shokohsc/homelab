# nfs-proxmox

NFS server (Export/Share) publishing the Proxmox datastore, used for VM backups and the downloads PVC.

| | |
|---|---|
| Namespace | `nfs-proxmox` |
| Flux Kustomization | `requirements` |
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
| [`service.yaml`](service.yaml) | Service |
