# containerdevops

Reusable GitHub Actions workflows and templates for production-grade container
images — hadolint, buildx, container-structure-test, Trivy/Syft/Grype, SBOM,
signing, GHCR and Docker Hub publishing, plus KICS and Compose Spec validation.

Guardrails: [pirlruc/guardrails `docker/`](https://github.com/pirlruc/guardrails/tree/main/docker)
(`DOCKER-*`). Pin this repo by commit SHA (`CI-018`).

## Workflows

| Workflow | Purpose |
|----------|---------|
| `container-lint.yml` | hadolint, shellcheck on entrypoint scripts, actionlint |
| `container-build.yml` | buildx (no push), structure-test, dive, size gate |
| `container-scan.yml` | Trivy + Syft SBOM + Grype on the **built image** |
| `container-publish.yml` | Multi-arch push to GHCR and Docker Hub; optional cosign + provenance |
| `container-iac.yml` | KICS + `docker compose config` + Compose Spec schema |

All workflows accept `blocking` (default `false`) using the cppdevops advisory
pattern, and are callable via `workflow_call` or manual `workflow_dispatch`.

## Caller example

```yaml
name: Container
on:
  workflow_dispatch:
    inputs:
      blocking:
        type: boolean
        default: false
jobs:
  lint:
    uses: pirlruc/containerdevops/.github/workflows/container-lint.yml@<sha>
    with:
      dockerfile: Dockerfile
      blocking: ${{ inputs.blocking }}
  build:
    uses: pirlruc/containerdevops/.github/workflows/container-build.yml@<sha>
    with:
      context: .
      dockerfile: Dockerfile
      blocking: ${{ inputs.blocking }}
```

Publish workflows need `packages: write`, `id-token: write`, and Docker Hub
credentials (`DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN`) when pushing to Docker Hub.
Signing (`sign: true`) is intended for public repositories; private repos should
record `DOCKER-SEC-003` / `DOCKER-SEC-004` deviations until they go public or move
to Enterprise Cloud.

## Local parity

```bash
bash scripts/check-container-local.sh --dockerfile Dockerfile --context .
```

Tools missing from the host PATH run via digest-pinned images (see the script's
resolution table). No system install required.

## Bootstrap a consumer

```bash
./scripts/sync-container-tooling.sh /path/to/consuming-repo
```

Creates create-once `.github/workflows/ci-container.yml` and seeds scan configs
from `templates/` when missing.

## Layout

| Path | Purpose |
|------|---------|
| `.github/workflows/` | Reusable workflows |
| `scripts/` | Threshold readers, gates, local parity, sync |
| `templates/` | hadolint, trivy, grype, syft, structure-test, kics, thin caller |
| `docs/guardrails/` | Pinned submodule |
| `.github/scaffold/` | Pinned submodule |
