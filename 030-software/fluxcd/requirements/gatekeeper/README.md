# Gatekeeper

The `gatekeeper-library` Flux Kustomization: upstream Gatekeeper constraint templates, consumed by the constraints in `apps/gatekeeper`.

| | |
|---|---|
| Namespace | `gatekeeper-system` |
| Flux Kustomization | `requirements` |
| Reconciled | yes, from `../kustomization.yaml` |

## Manifests

| File | Contents |
|---|---|
| https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.22.2/deploy/gatekeeper.yaml | remote manifest |
| [`library.yaml`](library.yaml) | GitRepository, Kustomization |

## Substitutions

Flux `postBuild` values used here: `${interval}`.
