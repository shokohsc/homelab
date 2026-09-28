---
name: devops
description: MUST load whenever writing or modifying Git repository code.
---

# DevOps CI/CD Skill

## Purpose

Build and deploy containerized applications reliably to Kubernetes clusters running on Talos Linux.

The default approach is:

**GitHub → GitHub Actions → OCI image registry → Kubernetes → Flux/GitOps**

Keep pipelines small, reproducible, secure, and easy to debug.

---

## CI Principles

### Prefer

* Prefer GitHub Actions for CI.
* Prefer one workflow per responsibility rather than one large workflow.
* Prefer immutable container image tags such as Git SHA.
* Prefer publishing OCI images to a registry.
* Prefer multi-stage container builds.
* Prefer rootless container images when practical.
* Prefer minimal runtime images.
* Prefer reproducible builds.
* Prefer dependency and base-image pinning where practical.
* Prefer automated vulnerability scanning.
* Prefer SBOM generation.
* Prefer image signing and provenance/attestation.
* Prefer failing fast on formatting, linting, tests, and build errors.
* Prefer caching only when it makes builds significantly faster without reducing reproducibility.
* Prefer GitHub Actions' native permissions with the minimum required access.
* Prefer OIDC over long-lived cloud or registry credentials.
* Prefer pull requests to validate changes before merging.
* Prefer the same container image built by CI to be promoted through environments.

### Avoid

* Avoid building images directly on Kubernetes nodes.
* Avoid privileged Docker-in-Docker unless there is a specific requirement.
* Avoid mutable production tags such as `latest`.
* Avoid embedding credentials in workflows, repositories, or container images.
* Avoid unnecessary pipeline stages.
* Avoid rebuilding the same application independently for each environment.
* Avoid depending on the CI runner's local state.
* Avoid downloading arbitrary scripts and executing them without verification.
* Avoid ignoring vulnerability-scanner failures without an explicit reason.
* Avoid making CI dependent on external services when a deterministic local test is sufficient.

---

## Container Image Generation

### Prefer

* Prefer OCI-compatible images.
* Prefer BuildKit-based builds.
* Prefer `docker buildx` or another BuildKit-based builder.
* Prefer multi-platform builds only when platforms are actually required.
* Prefer immutable tags based on the Git commit SHA.
* Prefer publishing additional human-readable tags such as `main` or semantic versions only as aliases.
* Prefer OCI labels containing source repository, revision, version, and build metadata.
* Prefer non-root runtime containers.
* Prefer `.dockerignore` files.
* Prefer copying only required artifacts into the final image.
* Prefer distroless or minimal runtime images when operationally appropriate.
* Prefer image signing with a keyless/OIDC-based mechanism.
* Prefer SBOM and provenance attestations.

Example tagging scheme:

```text
ghcr.io/example/app:<git-sha>
ghcr.io/example/app:v1.4.0
```

The Git SHA should be the immutable deployment reference.

### Avoid

* Avoid `latest` as a production deployment reference.
* Avoid shipping compilers, package managers, source code, or build tools in runtime images.
* Avoid running containers as root unless required.
* Avoid putting secrets into Dockerfile `ARG` or `ENV` values.
* Avoid using a full Linux distribution as the runtime image without a reason.
* Avoid relying on image tags alone to identify an exact production artifact.

---

## GitHub Actions

### Prefer

* Prefer reusable workflows for repeated CI patterns.
* Prefer explicit job dependencies.
* Prefer `permissions: {}` by default and grant only required permissions.
* Prefer GitHub OIDC for authentication to external systems.
* Prefer GitHub Container Registry or another OCI registry with short-lived credentials.
* Prefer dependency caching through supported GitHub Actions mechanisms.
* Prefer concurrency controls to cancel obsolete pull-request builds.
* Prefer separate workflows for pull requests, releases, and deployments.
* Prefer protected environments for production deployments.
* Prefer pinned or versioned GitHub Actions.
* Prefer Dependabot or Renovate for action and dependency updates.

A typical workflow should be approximately:

```text
checkout
  ↓
lint / test
  ↓
build image
  ↓
scan image
  ↓
generate SBOM / provenance
  ↓
push image
```

### Avoid

* Avoid giving workflows unrestricted repository permissions.
* Avoid storing static cloud credentials when OIDC is available.
* Avoid deploying directly from arbitrary pull requests.
* Avoid duplicating the same workflow logic across many repositories.
* Avoid workflows containing large amounts of shell scripting when an existing action or reusable workflow is clearer.
* Avoid production deployment from untrusted branches.

---

## Kubernetes / Talos

Talos should be treated as an immutable Kubernetes operating system.

CI should build and validate application artifacts; Kubernetes should handle deployment and runtime orchestration.

### Prefer

* Prefer GitOps for Kubernetes deployments.
* Prefer Flux for continuous delivery.
* Prefer committing desired Kubernetes state rather than imperatively modifying the cluster from CI.
* Prefer Kubernetes manifests, Kustomize, Helm, or another declarative format.
* Prefer immutable image references.
* Prefer Kubernetes Secrets backed by an appropriate secret-management solution.
* Prefer readiness and liveness probes where appropriate.
* Prefer resource requests and limits.
* Prefer Pod Security standards and non-root workloads.
* Prefer network policies where appropriate.
* Prefer GitOps reconciliation as the deployment mechanism.
* Prefer CI validating manifests before they reach the cluster.

A preferred deployment flow is:

```text
Developer
   ↓
Git commit / Pull Request
   ↓
GitHub Actions
   ↓
Tests + image build + security checks
   ↓
OCI registry
   ↓
GitOps repository update
   ↓
Flux
   ↓
Talos Kubernetes
```

### Avoid

* Avoid SSH access to Talos nodes for application deployment.
* Avoid `kubectl apply` from CI for normal deployments.
* Avoid treating Kubernetes nodes as mutable servers.
* Avoid manually changing workloads in production.
* Avoid storing application configuration directly on Talos nodes.
* Avoid relying on node-local state.
* Avoid deploying mutable image tags.

---

## Continuous Delivery

### Prefer

* Prefer automatic deployment to development environments.
* Prefer GitOps promotion between environments.
* Prefer pull requests for production changes when approval is required.
* Prefer image promotion by changing the immutable image reference.
* Prefer Flux image automation when automatic image updates are desired.
* Prefer progressive deployment mechanisms when application risk justifies them.
* Prefer health checks and automatic rollback mechanisms.
* Prefer keeping environment-specific configuration separate from application source code.

### Avoid

* Avoid manually copying images between registries when promotion can be declarative.
* Avoid production deployments that depend on a developer's workstation.
* Avoid making production state different from Git without documenting why.
* Avoid automatic production deployment of unreviewed changes unless the environment explicitly permits it.
* Avoid complicated release orchestration when GitOps reconciliation is sufficient.

---

## Testing

### Prefer

Run the cheapest useful validation first:

```text
format
  ↓
lint
  ↓
unit tests
  ↓
build
  ↓
container test
  ↓
security scan
```

Prefer testing the container that will actually be deployed rather than testing only the source tree.

For Kubernetes workloads, validate:

* Kubernetes manifests
* Kustomize/Helm rendering
* schema correctness
* security configuration
* resource configuration
* container image references

### Avoid

* Avoid expensive integration tests when a unit test provides equivalent coverage.
* Avoid tests that depend on production infrastructure.
* Avoid making every CI job require a Kubernetes cluster unless the test genuinely needs one.

---

## Security

### Prefer

* Prefer least-privilege GitHub Actions permissions.
* Prefer short-lived credentials.
* Prefer OIDC.
* Prefer signed container images.
* Prefer SBOMs.
* Prefer provenance attestations.
* Prefer dependency scanning.
* Prefer container vulnerability scanning.
* Prefer secret scanning.
* Prefer Renovate or Dependabot.
* Prefer regular base-image updates.
* Prefer non-root containers.

### Avoid

* Avoid plaintext secrets.
* Avoid secrets in Git history.
* Avoid long-lived registry tokens.
* Avoid privileged containers unless required.
* Avoid ignoring critical vulnerabilities indefinitely.
* Avoid running arbitrary pull-request code with production credentials.

---

## Versioning

### Prefer

Use Git commits as the immutable source of truth.

For released applications, prefer:

```text
v1.2.3
```

with the corresponding immutable image:

```text
ghcr.io/example/app:<git-sha>
```

Kubernetes should ultimately reference the immutable artifact.

### Avoid

* Avoid using `latest` to determine what is running in production.
* Avoid manually maintained version strings in multiple places.
* Avoid rebuilding an existing version with different source code.

---

## Simplicity Rules

### Prefer

* Prefer the simplest pipeline that provides sufficient safety.
* Prefer existing GitHub Actions and standard tooling.
* Prefer declarative configuration.
* Prefer one obvious way to build an image.
* Prefer one obvious way to deploy it.
* Prefer automation over documentation for repeatable operations.
* Prefer boring infrastructure that is easy to troubleshoot.

### Avoid

* Avoid introducing a tool solely because it is popular.
* Avoid abstractions that hide the actual build or deployment process.
* Avoid creating a custom CI platform when GitHub Actions is sufficient.
* Avoid adding Kubernetes operators for tasks that can be handled by GitOps.
* Avoid making CI/CD dependent on a complex chain of external services.

---

## Default Stack

Unless there is a concrete reason to use something else:

```text
Source:
  GitHub

CI:
  GitHub Actions

Build:
  BuildKit / docker buildx

Registry:
  OCI-compatible registry / GHCR

Security:
  Trivy or equivalent
  SBOM
  image signing
  provenance

Deployment:
  Flux

Kubernetes configuration:
  Kustomize or Helm

Cluster:
  Talos Linux
```

The overall goal is **reproducible builds, immutable artifacts, declarative deployments, minimal credentials, and as little CI/CD complexity as possible**.
