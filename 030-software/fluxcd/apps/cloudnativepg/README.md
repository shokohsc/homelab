# CloudNativePG

Custom resource definitions and cluster-scoped resources for the CloudNativePG operator, installed from a remote manifest.

| | |
|---|---|
| Namespace | `cnpg-system` |
| Flux Kustomization | `apps` |
| Reconciled | yes, from `../kustomization.yaml` |

## Endpoints

- https://cnpg-platform.${domain}
- https://postgres.${domain}

## Images

- `ghcr.io/shokohsc/cnpg-platform:02450a6`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `spec` | "1" / 256Mi | - / 1024Mi |
| `cnpg-platform` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`cluster.yaml`](cluster.yaml) | Cluster |
| [`routes.yaml`](routes.yaml) | TCPRoute |
| [`secret.yaml`](secret.yaml) | Secret |
| [`database-roles/atuin.yaml`](database-roles/atuin.yaml) | Database, DatabaseRole |
| [`database-roles/ferretdb.yaml`](database-roles/ferretdb.yaml) | Database, DatabaseRole |
| [`database-roles/maddy.yaml`](database-roles/maddy.yaml) | Database, DatabaseRole |
| [`database-roles/miniflux.yaml`](database-roles/miniflux.yaml) | Database, DatabaseRole |
| [`database-roles/pocket-id.yaml`](database-roles/pocket-id.yaml) | Database, DatabaseRole |
| [`database-roles/radarr.yaml`](database-roles/radarr.yaml) | Database, DatabaseRole |
| [`database-roles/sonarr.yaml`](database-roles/sonarr.yaml) | Database, DatabaseRole |
| [`database-roles/prowlarr.yaml`](database-roles/prowlarr.yaml) | Database, DatabaseRole |
| [`database-roles/sftpgo.yaml`](database-roles/sftpgo.yaml) | Database, DatabaseRole |
| [`database-roles/vaultwarden.yaml`](database-roles/vaultwarden.yaml) | Database, DatabaseRole |
| [`database-roles/sidekick.yaml`](database-roles/sidekick.yaml) | Database, DatabaseRole |
| [`database-roles/kubeopencode.yaml`](database-roles/kubeopencode.yaml) | Database, DatabaseRole |

## Substitutions

Flux `postBuild` values used here: `${domain}`.
