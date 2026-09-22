---
name: kubernetes
description: MUST load whenever writing or modifying Kubernetes, Helm, FluxCD or any CRDs (Custom Resource Definitions) code.
---

Prefer:

- plain kubernetes kustomize yaml manifests
- pod specification follows strict admission policy
- request and limits resources defined
- gateway httproute
- gateway listenerset for sub domain httproutes
- pod anti affinity
- simple label selector (i.e: app=app_name)
- service port 80

Avoid:

- fluxcd helmrelease
- ingress
