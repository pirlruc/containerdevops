# containerdevops

Reusable GitHub Actions workflows and templates for production-grade container
images — hadolint, buildx, container-structure-test, Trivy/Syft/Grype, SBOM,
signing, GHCR and Docker Hub publishing, plus KICS, Compose Spec validation,
and the `ci-container` toolchain image.

Guardrails: [pirlruc/guardrails `docker/`](https://github.com/pirlruc/guardrails/tree/1.6.0/docker)
(`DOCKER-*`), pinned at `docs/guardrails/` tag `1.6.0`. Pin this repo by commit SHA (`CI-018`).

## Workflows

| Workflow | Purpose |
|----------|---------|
| `container-lint.yml` | hadolint, shellcheck; optional nested commondevops infra/secrets |
| `container-build.yml` | buildx (no push), structure-test, dive, size gate (`du -sxm /`) |
| `container-scan.yml` | Trivy + Syft SBOM + Grype on the **built image** |
| `container-published-rescan.yml` | GHCR probe + `container-scan.yml` for a published registry tag |
| `container-publish.yml` | Multi-arch push to GHCR and Docker Hub; optional cosign + provenance |
| `container-iac.yml` | KICS + `docker compose config` + DOCKER-COMPOSE measurable gates |
| `container-devcontainer.yml` | Devcontainer Dockerfile lint (structure-test stub) |
| `ci-container-image.yml` | Publish `ghcr.io/pirlruc/ci-container` |

All workflows accept `blocking` (default `false`) using the advisory pattern, and
are callable via `workflow_call` or manual `workflow_dispatch`.

See [docs/workflows.md](docs/workflows.md) for **required caller permissions**
(CI-031 — a reusable workflow cannot escalate beyond the caller's grant).

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
    permissions:
      contents: read
      security-events: write
    uses: pirlruc/containerdevops/.github/workflows/container-lint.yml@<sha>
    with:
      dockerfile: Dockerfile
      scripts_ref: <sha>
      blocking: ${{ inputs.blocking }}
    secrets:
      checkout_token: ${{ secrets.COMMONDEVOPS_READ_TOKEN }}
      scripts_token: ${{ secrets.CONTAINERDEVOPS_READ_TOKEN }}
  build:
    permissions:
      contents: read
      packages: read
    uses: pirlruc/containerdevops/.github/workflows/container-build.yml@<sha>
    with:
      context: .
      dockerfile: Dockerfile
      scripts_ref: <sha>
      blocking: ${{ inputs.blocking }}
    secrets:
      scripts_token: ${{ secrets.CONTAINERDEVOPS_READ_TOKEN }}
```

Publish workflows need `packages: write`, `id-token: write`, and Docker Hub
credentials (`DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN`) when pushing to Docker Hub.
Signing (`sign: true`) is intended for public repositories; private repos should
record `DOCKER-SEC-003` / `DOCKER-SEC-004` deviations until they go public or move
to Enterprise Cloud.

## Local parity

```bash
bash scripts/check-container-local.sh --dockerfile Dockerfile --context .
# CI toolchain images:
bash scripts/check-container-local.sh --dockerfile docker/ci-container/Dockerfile.alpine \
  --context docker/ci-container --size-class ci_toolchain
```

Tools missing from the host PATH run via digest-pinned images (see the script's
resolution table). No system install required.

## Bootstrap a consumer

```bash
./scripts/sync-container-tooling.sh /path/to/consuming-repo
```

Creates create-once `.github/workflows/ci-container.yml` and seeds scan configs
from `templates/` when missing.

## Toolchain image

`ghcr.io/pirlruc/ci-container` extends [commondevops `ci-lint`](https://github.com/pirlruc/commondevops)
with dive and container-structure-test.

Consumer docs:

- Docker Hub: [docs/docker-hub.md](docs/docker-hub.md)
- GitHub Packages: [docs/github-packages.md](docs/github-packages.md)

## Layout

| Path | Purpose |
|------|---------|
| `.github/workflows/` | Reusable workflows |
| `scripts/` | Threshold readers, gates, local parity, sync |
| `templates/` | hadolint, trivy, grype, syft, structure-test, kics, thin caller |
| `docs/guardrails/` | Pinned submodule |
| `.github/scaffold/` | Pinned submodule |
