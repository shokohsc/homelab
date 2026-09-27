# Mountpoint for Amazon S3 CSI Driver

[awslabs/mountpoint-s3-csi-driver](https://github.com/awslabs/mountpoint-s3-csi-driver)
pinned to **v2.8.0**, vendored from `deploy/kubernetes/base/` (the upstream
`kubectl apply -k ...?ref=v2.8.0` path). Not a HelmRelease on purpose: upstream
stops shipping installable in-repo Helm charts after 2026-09-01.

Exposes S3 buckets as `ReadWriteMany` PersistentVolumes. The default backend is
the in-cluster [RustFS](../../apps/rustfs) (`http://rustfs-svc.rustfs.svc.cluster.local:9000`).

## One manual step: the `aws-secret`

Talos has no OIDC issuer (IRSA) and no IMDS (node IAM profiles), and this is not
EKS, so Pod Identity is out. The only credential source the driver can use here
is a static Kubernetes secret, and the driver reads it **once at startup** — the
secret must exist before the DaemonSet first comes up, and rotating it requires
a DaemonSet restart.

Create it yourself (this pod has no access to the repo's PGP key, so the secret
cannot be committed by the PR):

```console
$ kubectl -n mountpoint-s3-csi create secret generic aws-secret \
    --from-literal key_id=<RUSTFS_ACCESS_KEY> \
    --from-literal access_key=<RUSTFS_SECRET_KEY> \
    --dry-run=client -o yaml > aws-secret.yaml
$ sops --encrypt --in-place aws-secret.yaml    # picks up 030-software/fluxcd/core/.sops.yaml
$ cp aws-secret.yaml ../../infrastructure/mountpoint-s3-csi/secret.yaml
```

Values come from the RustFS HelmRelease secret (`sops -d` on
`apps/rustfs/secret.yaml`). The env refs in `node.yaml` are `optional: true`, so
the DaemonSet starts fine without the secret and simply has no credentials —
mounts will fail at `NodePublishVolume` with an auth error.

## Usage

**No dynamic provisioning** — `CreateVolume`/`DeleteVolume` return `Unimplemented`
in v2.8.0, so there is no StorageClass. Use static provisioning:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: rustfs-bucket
spec:
  accessModes: [ReadWriteMany]      # or ReadOnlyMany
  capacity:
    storage: 1200Gi                 # ignored, but required
  storageClassName: ""              # required: empty for static provisioning
  claimRef:                         # stops other PVCs claiming it
    namespace: default
    name: rustfs-bucket
  mountOptions:                     # Mountpoint flags, see mountpoint-s3 doc/CONFIGURATION.md
    - region us-east-1
  csi:
    driver: s3.csi.aws.com
    volumeHandle: rustfs-bucket     # must be unique
    volumeAttributes:
      bucketName: my-bucket
      authenticationSource: driver  # driver (default) | pod
      cache: emptyDir               # emptyDir | ephemeral
      cacheEmptyDirSizeLimit: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rustfs-bucket
spec:
  accessModes: [ReadWriteMany]
  resources:
    requests:
      storage: 1200Gi
  storageClassName: ""
  volumeName: rustfs-bucket
```

## Deviations from upstream

| Change | Why |
| --- | --- |
| Driver lives in `mountpoint-s3-csi`, not `kube-system` | repo convention; `kube-system` is not Flux-managed here |
| Image pinned to `v2.8.0` in both the DaemonSet and `MOUNTPOINT_IMAGE` | replaces upstream's kustomize `replacements` |
| `hostPID: true` on `s3-csi-node` | required for Mountpoint PID semantics; upstream leaves it off only because kustomize cannot detect OpenShift ([#626](https://github.com/awslabs/mountpoint-s3-csi-driver/issues/626)) |
| `tokenRequests` dropped from the `CSIDriver` | EKS Pod Identity only |
| `EKS_POD_IDENTITY_AGENT_CONTAINER_CREDENTIALS_FULL_URI` dropped | EKS only |
| `eks.amazonaws.com/compute-type` nodeAffinity dropped | no Fargate/hybrid nodes |
| `MOUNTPOINT_POD_LABELS` sets two gatekeeper exemptions | the generated Mountpoint Pods have no `readOnlyRootFilesystem` and no resources, which `psp-readonlyrootfilesystem` and `container-must-have-limits` forbid |
| `mountpoint-s3-csi` added to Gatekeeper `excludedNamespaces` | `hostPath` + `privileged`, same as `ceph-csi` |
| `mount-s3` namespace kept at Pod Security `restricted` | the generated Pods do pass it |

## Notes

* No `s3.csi.aws.com/agent-not-ready` node taint is set. The driver would remove
  it on startup, but only if it existed — worth adding via Talos
  `register-with-taints` if you hit node-startup mount races.
* Mountpoint Pods tolerate every taint and are pinned to their workload's node by
  name, so the non-uniform-memory nodes are covered.
