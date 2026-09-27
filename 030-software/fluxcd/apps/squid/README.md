# Squid

Squid forward proxy with nginx in front and the squid-exporter for metrics.

| | |
|---|---|
| Namespace | `squid` |
| Flux Kustomization | `apps` |
| Reconciled | **no** - commented out in [`../kustomization.yaml`](../kustomization.yaml) |

## Endpoints

- https://squid.${domain}

## Images

- `ubuntu/squid:latest`
- `boynux/squid-exporter:v1.13.0`
- `nginx:1.31.6-alpine`

## Resources

| Container | requests (cpu / memory) | limits (cpu / memory) |
|---|---|---|
| `squid` | 100m / - | - / 512Mi |
| `squid-exporter` | 100m / - | - / 2048Mi |
| `nginx` | 100m / - | - / 64Mi |

## Manifests

| File | Contents |
|---|---|
| [`deployment.yaml`](deployment.yaml) | Deployment |
| [`namespace.yaml`](namespace.yaml) | Namespace |
| [`service.yaml`](service.yaml) | Service |
| [`http-route.yaml`](http-route.yaml) | HTTPRoute |
| [`routes.yaml`](routes.yaml) | TCPRoute |
| [`pvc.yaml`](pvc.yaml) | PersistentVolumeClaim |

## Substitutions

Flux `postBuild` values used here: `${domain}`, `${timezone}`.

## Enabling

This app is present on disk but commented out in [`../kustomization.yaml`](../kustomization.yaml), so Flux does not reconcile it. Uncomment the `- squid` entry and sync to deploy.
