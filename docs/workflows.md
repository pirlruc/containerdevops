# Workflows reference

All workflows: `workflow_call` + `workflow_dispatch`, `blocking` default `false`
(`ADVISORY` env + `continue-on-error` on gate steps).

## Shared inputs

| Input | Default | Meaning |
|-------|---------|---------|
| `blocking` | `false` | When true, gate failures fail the job |

## Shared secrets (private callers)

| Secret | Required | Meaning |
|--------|----------|---------|
| `scripts_token` | When caller ≠ this repo and this repo is private | Token with `contents:read` on `pirlruc/containerdevops` for sparse-checkout of `scripts/` |
| `checkout_token` | Nested commondevops calls from private repos | Passed through to commondevops reusables (`contents:read` on `pirlruc/commondevops`) |

## Shared inputs (cross-repo callers)

| Input | Required | Meaning |
|-------|----------|---------|
| `scripts_ref` | Cross-repo callers | Commit/tag/branch matching the `uses: …@pin` — scripts checkout uses this. Same-repo `workflow_dispatch` falls back to `github.sha`. Do **not** use `github.workflow_sha` (that is the caller’s workflow). |

Reusable jobs sparse-checkout this repository into `_containerdevops` for
`scripts/` (install helpers + vendored `docker.profile.thresholds.yml`).
The caller’s `GITHUB_TOKEN` cannot read a different private repository, so
private consumers must pass `scripts_token`. Same-repo `workflow_dispatch`
falls back to `github.token`.

Thresholds are vendored under `scripts/` because `docs/guardrails` is a private
submodule and is not available from nested checkout. Keep the vendored file in
sync with the guardrails docker pack.

## Required caller permissions

A reusable workflow **cannot escalate** beyond the permissions the caller job
grants. Callers must mirror (or exceed) the callee job’s `permissions:` block
or the run fails at startup before any step runs.

| Workflow | Caller job must grant |
|----------|----------------------|
| `container-lint.yml` | `contents: read`; add `security-events: write` when `run_secrets_scan: true` |
| `container-build.yml` | `contents: read`, `packages: read` |
| `container-scan.yml` | `contents: read`, `security-events: write` |
| `container-publish.yml` | `contents: read`, `packages: write`, `id-token: write` |
| `container-iac.yml` | `contents: read`, `security-events: write` |
| `container-devcontainer.yml` | `contents: read` |

## container-lint.yml

| Input | Default |
|-------|---------|
| `dockerfile` | `Dockerfile` |
| `working_directory` | `.` |
| `shell_scripts` | `""` |

## container-build.yml

| Input | Default |
|-------|---------|
| `context` | `.` |
| `dockerfile` | `Dockerfile` |
| `image_name` | `containerdevops-ci:local` |
| `structure_test_config` | `container-structure-test.yml` |
| `platforms` | `linux/amd64` |

Optional secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` — when set, the job
logs in to **`dhi.io`** before Buildx so Community Docker Hardened Image `FROM`
lines can pull. Pass the same Hub credentials used for Docker Hub publish.
Optional secret `ghcr_token` — PAT with `read:packages` when pulling a private
GHCR base (otherwise `github.token` when Actions package access is granted).

Optional input: `dhi_login` (default false) — when true, log in to dhi.io using
those secrets. Do not use `secrets` in `if:` on reusable workflows.

Optional OCI label inputs: `image_title` (defaults to `image_name`),
`image_description` (defaults to `image_name`). Prefer image-specific text —
do not pass the repository description.

Uploads `container-image` artifact (`image.tar`).

**Size gate:** `scripts/check-image-size.sh` measures the image via
`docker image inspect --format '{{.Size}}'`. On classic Docker Engine this is
approximately the uncompressed rootfs; under containerd image-store hosts the
same field can report a compressed value. Prefer validating thresholds against
a GitHub-hosted runner (or `du -sxm /` inside a disposable container) when
tuning `image_max_size_mb`.

## container-scan.yml

| Input | Default |
|-------|---------|
| `image` | required |
| `image_artifact` | `""` (optional tarball load) |
| `pkg_types` | `os,library` |

Honors `.trivyignore.yaml` or `.trivyignore` in the **caller** workspace when
present.

## container-publish.yml

| Input | Default |
|-------|---------|
| `image_name` | required |
| `dockerhub_image` | `""` (set to `namespace/name` to push Hub) |
| `platforms` | `linux/amd64,linux/arm64` |
| `sign` | `false` |
| `image_title` | `""` (override OCI title; empty keeps metadata-action default) |
| `image_description` | `""` (override OCI description; consumer-facing, max 512 chars) |
| `image_documentation` | `""` (override OCI documentation URL) |
| `image_url` | `""` (override OCI url) |
| `image_vendor` | `""` (override OCI vendor) |
| `dockerhub_readme` | `""` (path in caller checkout pushed as Hub Overview) |
| `dockerhub_short_description` | `""` (Hub short description when readme is set) |

Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` when Hub enabled **or** when
the Dockerfile pulls from `dhi.io`. Optional `ghcr_token` for private GHCR
pulls. The publish job logs in to `dhi.io` when those Hub secrets are present
(in addition to GHCR / Hub push logins). Permissions: `packages: write`,
`id-token: write` (provenance via `actions/attest-build-provenance` when
`sign: true`; no separate `attestations: write` grant is required on Free plan
private repos — keep `sign: false` there).

When `dockerhub_image` and `dockerhub_readme` are both set, the job pushes the
readme as the Docker Hub Overview after the image push. The Hub token needs
read/write/delete (admin-level) scope for the description API.

## container-iac.yml

| Input | Default |
|-------|---------|
| `paths` | `.` |
| `exclude_paths` | `""` |
| `compose_files` | `""` |
| `kics_config` | `.github/kics.config` |

KICS `exclude-queries` IDs and why each is suppressed (not fixed) are recorded in
[`docs/kics-exclusions.md`](kics-exclusions.md) (DOCKER-LINT-002).
