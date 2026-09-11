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
| `container-scan.yml` | `contents: read`, `security-events: write`, `packages: read` |
| `container-published-rescan.yml` | `contents: read`, `security-events: write`, `packages: read` |
| `container-publish.yml` | `contents: read`, `packages: write`, `id-token: write` |
| `container-iac.yml` | `contents: read`, `security-events: write` |
| `container-devcontainer.yml` | `contents: read` |

## container-lint.yml

| Input | Default |
|-------|---------|
| `dockerfile` | `Dockerfile` |
| `working_directory` | `.` |
| `shell_scripts` | `""` |
| `scripts_ref` | `""` |
| `runner_image` | `""` (host install when empty) |
| `run_infra_lint` | `true` |
| `run_secrets_scan` | `true` |
| `blocking` | `false` |

Nested commondevops pin: keep `uses:` and `scripts_ref` in lockstep (currently
tag `2.0.2`).

## container-build.yml

| Input | Default |
|-------|---------|
| `context` | `.` |
| `dockerfile` | `Dockerfile` |
| `image_name` | `containerdevops-ci:local` |
| `structure_test_config` | `container-structure-test.yml` |
| `platforms` | `linux/amd64` |
| `scripts_ref` | `""` |
| `blocking` | `false` |
| `artifact_name` | `container-image` |

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

Uploads the image tarball under `artifact_name` (default `container-image`).
When a caller runs multiple builds in one workflow (e.g. distro variants), pass
distinct `artifact_name` values so downloads stay unambiguous.

**BuildKit GHA cache:** `cache-from` / `cache-to` use `type=gha` with
`scope=<artifact_name>` so parallel variant builds do not thrash a shared cache.

**Size gate:** `scripts/check-image-size.sh` measures the image rootfs via
`du -sxm /` inside a disposable container. This is store-independent (unlike
`docker image inspect .Size`, which reports uncompressed size on classic Docker
Engine / GHA runners but a compressed value under containerd image-store hosts).
Tune `image_max_size_mb` against this measurement.

## container-scan.yml

| Input | Default |
|-------|---------|
| `image` | required |
| `image_artifact` | `""` (optional tarball load) |
| `pkg_types` | `os,library` |
| `ignorefile` | `""` |
| `blocking` | `false` |
| `scripts_ref` | `""` |
| `results_artifact` | `container-scan-results` |
| `sarif_category` | `trivy-image` |

Callers scanning a **registry** ref (`ghcr.io/...`) must grant `packages: read`.
The scan job logs in to GHCR and `docker pull`s on the same runner — a preceding
probe job's login does not carry over. Optional secret `ghcr_token` (PAT with
`read:packages`) when `github.token` cannot pull; otherwise `github.token`.
Artifact-loaded local tags skip login.

`ignorefile` contract:

| Value | Behaviour |
|-------|-----------|
| path to a file | Use that ignorefile (`--ignorefile <path>`) |
| empty (`""`) | Fall back to caller-workspace `.trivyignore.yaml` or `.trivyignore` when present |
| `none` | Disable all ignorefiles (for advisory posture scans that must not suppress findings) |

Local parity: `bash scripts/check-container-local.sh --no-ignorefile` mirrors
`ignorefile: none`.

When a caller runs multiple scans in one workflow (blocking + posture, or distro
variants), pass distinct `results_artifact` and `sarif_category` values so
artifact downloads and code-scanning uploads do not collide or overwrite.

## container-published-rescan.yml

Probe a registry tag (GHCR login + `docker pull`) then, when the image is
present, call `container-scan.yml` on the same `image`. The probe fails fast
when the tag is not pullable so Trivy/Syft/Grype do not run. After `3.0.1`
the scan job also logs in to GHCR; the probe's Docker state does not carry
over.

Same-repo callers use `uses: ./.github/workflows/container-published-rescan.yml`.
Cross-repo callers pin a SHA **after this workflow is on the default branch**
and pass matching `scripts_ref`. Do not pin a SHA that only exists on an
unreleased branch from another private repo.

| Input | Default |
|-------|---------|
| `image` | required |
| `ignorefile` | `""` |
| `pkg_types` | `os,library` |
| `blocking` | `false` |
| `scripts_ref` | `""` (must match `uses:` pin; forwarded to `container-scan.yml`) |
| `results_artifact` | `container-scan-results` |
| `sarif_category` | `trivy-image` |

Secrets: `ghcr_token`, `scripts_token` (both optional; forwarded to
`container-scan.yml`). Caller job must grant `packages: read`.

`containerdevops-security.yml` uses this reusable for
`ghcr.io/pirlruc/ci-container:latest`. commondevops / cppdevops stay on
`container-scan.yml@3.0.1` until they can pin a released SHA of this file.

## container-publish.yml

| Input | Default |
|-------|---------|
| `image_name` | required |
| `dockerhub_image` | `""` (set to `namespace/name` to push Hub) |
| `platforms` | `linux/amd64,linux/arm64` |
| `sign` | `false` |
| `verify_command` | `/bin/true` (simple argv only — no shell metacharacters) |
| `image_title` | `""` (override OCI title; empty keeps metadata-action default) |
| `image_description` | `""` (override OCI description; consumer-facing, max 512 chars) |
| `image_documentation` | `""` (override OCI documentation URL) |
| `image_url` | `""` (override OCI url) |
| `image_vendor` | `""` (override OCI vendor) |
| `dockerhub_readme` | `""` (path in caller checkout pushed as Hub Overview) |
| `dockerhub_short_description` | `""` (Hub short description when readme is set) |
| `tag_suffix` | `""` (e.g. `-alpine`, `-debian`; empty = legacy unsuffixed tags only) |
| `tag_alias_unsuffixed` | `true` (when `tag_suffix` is set, also publish the unsuffixed tag set) |

### Variant tagging contract

Callers that publish two distro variants of the same `image_name` pass a
distinct `tag_suffix` per publish job (e.g. `-alpine`, `-debian`). Set
`tag_alias_unsuffixed: true` on the **lower-vulnerability** variant so it owns
the unsuffixed tags (`{{version}}`, `latest`, …). Set
`tag_alias_unsuffixed: false` on the other variant so it only publishes the
suffixed tags. Empty `tag_suffix` preserves the pre-variant behaviour (unsuffixed
tags only).

**Hub Overview sync:** when both `dockerhub_image` and `dockerhub_readme` are
set, the Overview is pushed only for the variant that owns unsuffixed tags
(`tag_suffix` empty, or `tag_alias_unsuffixed: true`). Other variants should
still pass the same `dockerhub_readme` path for documentation, but the sync
step is skipped so parallel publishes do not race on the Hub description.

**BuildKit GHA cache:** publish uses `scope=publish-<image_name><tag_suffix>` so
variant jobs keep separate caches.

Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` when Hub enabled **or** when
the Dockerfile pulls from `dhi.io`. Optional `ghcr_token` for private GHCR
pulls. The publish job logs in to `dhi.io` when those Hub secrets are present
(in addition to GHCR / Hub push logins). Permissions: `packages: write`,
`id-token: write` (provenance via `actions/attest-build-provenance` when
`sign: true`; no separate `attestations: write` grant is required on Free plan
private repos — keep `sign: false` there).

When `dockerhub_image` and `dockerhub_readme` are both set (and the variant
owns unsuffixed tags), the job pushes the readme as the Docker Hub Overview
after the image push. The Hub token needs read/write/delete (admin-level)
scope for the description API. A push-only token yields Forbidden; that step
is always advisory so image publish still succeeds.

## container-iac.yml

| Input | Default |
|-------|---------|
| `paths` | `.` |
| `exclude_paths` | `""` |
| `compose_files` | `""` |
| `kics_config` | `.github/kics.config` |

KICS `exclude-queries` IDs and why each is suppressed (not fixed) are recorded in
[`docs/kics-exclusions.md`](kics-exclusions.md) (DOCKER-LINT-002).

## container-devcontainer.yml

| Input | Default |
|-------|---------|
| `dockerfile` | `.devcontainer/Dockerfile` |
| `working_directory` | `.` |
| `structure_test_config` | `""` (skip when empty) |
| `scripts_ref` | `""` |
| `runner_image` | `""` (host install when empty) |
| `blocking` | `false` |

Lints the devcontainer Dockerfile (hadolint) and optionally runs
container-structure-test when `structure_test_config` is set.
