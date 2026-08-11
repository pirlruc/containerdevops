# Docker Hub — ci-container

Public overview for the
[pirlruc/ci-container](https://hub.docker.com/r/pirlruc/ci-container) image
(also published to `ghcr.io/pirlruc/ci-container`). Paste or adapt this page into
the Docker Hub **Overview**.

**ci-container** is a short-lived CI toolchain image for container lint jobs: it
extends `ci-lint` with dive and container-structure-test. It is not a product
runtime and has no `HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| Docker Hub | `pirlruc/ci-container` |
| GHCR | `ghcr.io/pirlruc/ci-container` |
| Architectures | `linux/amd64` |
| User | non-root `1000:1000` |
| Base | `ghcr.io/pirlruc/ci-lint` (digest-pinned at publish) |

### Tags

| Tag | Meaning |
|-----|---------|
| `2.0.0` | Immutable release (prefer the current semver) |
| `2.0` | Latest patch in the `2.0` line |
| `latest` | Latest non-prerelease publish |
| `sha-<git>` | Exact git SHA of the published commit |

Prefer a version tag or digest in production.

```bash
docker pull pirlruc/ci-container:2.0.0
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-container:2.0.0 \
  hadolint Dockerfile
```

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  pirlruc/ci-container:2.0.0 \
  dive --ci my-app:local
```

## What is inside

Everything in `ci-lint`, plus:

| Tool | Role |
|------|------|
| dive | Image layer efficiency |
| container-structure-test | Image structure / command tests |

Not included: syft, grype, trivy, grant, cosign (run on the plain runner or via
`ci-supply-chain`).

## Vulnerabilities

Donor Go binaries (dive, structure-test, actionlint) embed dependency CVEs that
only clear when upstream publishes a newer digest. Path-scoped Trivy ignores are
in the source repo `.trivyignore.yaml` with a review date. The publish gate uses
`--pkg-types library`.

## Access

Hub and GHCR packages may remain private until made public in the UI. Consumers
need package read access (or a PAT). Prefer digest pins.

## Source and support

- Source: https://github.com/pirlruc/containerdevops
- Releases: https://github.com/pirlruc/containerdevops/releases
- License: MIT
