# Workflows reference

All workflows: `workflow_call` + `workflow_dispatch`, `blocking` default `false`.
Finding steps collect then fail via `scripts/gate-aggregate.sh` (`ADVISORY` when
`blocking` is false). Missing thresholds or required tools fail closed regardless
of `blocking` (CI-022 / CI-035).

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
| `scripts_ref` | Cross-repo callers | Commit/tag/branch matching the `uses: …@pin` (CI-034). Same-repo `workflow_dispatch` falls back to `github.sha`. Do **not** use `github.workflow_sha` (that is the caller’s workflow). Empty `scripts_ref` on a cross-repo caller fails closed. |

Reusable jobs sparse-checkout this repository into `_containerdevops` for
`scripts/` (install helpers + vendored `docker.profile.thresholds.yml`).
The caller’s `GITHUB_TOKEN` cannot read a different private repository, so
private consumers must pass `scripts_token`. Same-repo `workflow_dispatch`
falls back to `github.token`.

Thresholds are vendored under `scripts/` because `docs/guardrails` is a private
submodule and is not available from nested checkout. Keep the vendored file in
sync with the guardrails docker pack.

## Required caller permissions (CI-031)

A reusable workflow **cannot escalate** beyond the permissions the caller job
grants. Callers must mirror (or exceed) the callee job’s `permissions:` block
or the run fails at startup before any step runs.

| Workflow | Caller job must grant |
|----------|----------------------|
| `container-lint.yml` | `contents: read`; add `security-events: write` when `run_secrets_scan: true` |
| `container-build.yml` | `contents: read`, `packages: write` |
| `container-scan.yml` | `contents: read`, `security-events: write`, `packages: read` |
| `container-published-rescan.yml` | `contents: read`, `security-events: write`, `packages: read` |
| `container-publish.yml` | `contents: read`, `packages: write`, `id-token: write` |
| `container-iac.yml` | `contents: read`, `security-events: write` |
| `container-devcontainer.yml` | `contents: read` |

## container-lint.yml

| Input | Default |
|-------|---------|
| `dockerfile` | `Dockerfile` (used when `dockerfiles` is empty) |
| `dockerfiles` | `""` (newline-separated list; replaces `dockerfile`) |
| `working_directory` | `.` |
| `shell_scripts` | `""` |
| `scripts_ref` | `""` |
| `runner_image` | `""` (host install when empty) |
| `run_infra_lint` | `true` |
| `run_secrets_scan` | `true` |
| `blocking` | `false` |

Nested commondevops pin: keep `uses:` and `scripts_ref` in lockstep (currently
tag `5.2.0` → `9b2e62121f832b15d865fc9bc51a3d462755e2b7`).

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
| `artifact_name` | `container-image` (cache scope + ephemeral tag suffix) |
| `push_handoff` | `true` (set `false` to skip the GHCR `ci-run-*` push) |
| `scan_local` | `false` (scan the loaded image in this job; no registry write) |
| `scanners` | `vuln,secret` (only when `scan_local` is true) |
| `handoff_package` | `""` (GHCR name; default is `image_name` before colon) |
| `size_class` | `application` |
| `image_max_size_mb` | `""` (override; empty reads the vendored key for `size_class`) |

Outputs: `digest` (`sha256:…`), `handoff_tag`, `handoff_package`, and
`image_ref` (`<pkg>@sha256:…` — **no** registry/owner).

After local load + CST/size/dive, the job pushes
`ghcr.io/<owner>/<handoff_package>:ci-run-<run_id>-<suffix>` and exports
those outputs. **Do not pass `needs.build.outputs.image_ref` as a docker
ref.** If `DOCKERHUB_USERNAME` equals `github.repository_owner`, Actions
drops any output that contains the owner (`Skip output since it may
contain secret`) and scan receives `""`. Compose on the caller:

```yaml
image: ${{ format('ghcr.io/{0}/{1}@{2}', github.repository_owner, needs.build.outputs.handoff_package, needs.build.outputs.digest) }}
```

**6.0.0 removed** `upload_image_artifact` and `image_artifact`. There is no image tar.
Unpublished images set `push_handoff: false` and `scan_local: true` on this
workflow. `container-scan` still accepts a local tag, but only when that tag
is already loaded on the same runner.

`size_class` selects the size floor (DOCKER-PERF-002): `application` reads
`image_max_size_mb` (300); `ci_toolchain` reads `ci_image_max_size_mb` (2000).
Pass `size_class: ci_toolchain` for `ci-lint` / `ci-container` / `ci-cpp` images.
`workflow_dispatch` is capped at 10 inputs — `size_class` is `workflow_call`-only;
dispatch callers can still pass `image_max_size_mb`.

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

**BuildKit GHA cache:** `cache-from` / `cache-to` use `type=gha,mode=min` with
`scope=<artifact_name>` so parallel variant builds do not thrash a shared cache.
`cache-to` is written only when the run ref is the default branch. Pull request
and tag runs restore that cache and do not create a per-ref copy (CI-004).

**Size gate:** `scripts/check-image-size.sh` measures the image rootfs via
`du -sxm /` inside a disposable container. This is store-independent (unlike
`docker image inspect .Size`, which reports uncompressed size on classic Docker
Engine / GHA runners but a compressed value under containerd image-store hosts).
Tune `image_max_size_mb` / `ci_image_max_size_mb` against this measurement.

## container-scan.yml

| Input | Default |
|-------|---------|
| `image` | required (GHCR ref is pulled; any other ref is a local tag) |
| `scanners` | `vuln,secret` (DOCKER-SEC-005) |
| `pkg_types` | `os,library` |
| `ignorefile` | `""` |
| `blocking` | `false` |
| `scripts_ref` | `""` |
| `results_artifact` | `container-scan-results` |
| `sarif_category` | `trivy-image` |

Callers should compose the GHCR digest ref from `handoff_package` + `digest`
(see container-build.yml above). A ref that does not start with `ghcr.io/` is
scanned as a local tag and is not pulled. `image_artifact` was removed in 6.0.0.

A missing `vuln_fail_on_severity` key fails closed (CI-022) before Trivy/Grype
run — it does not degrade to CRITICAL-only.

Callers scanning a **registry** ref (`ghcr.io/...`) must grant `packages: read`.
The scan job logs in to GHCR and `docker pull`s on the same runner — a preceding
probe job's login does not carry over. Optional secret `ghcr_token` (PAT with
`read:packages`) when `github.token` cannot pull; otherwise `github.token`.
Local tags skip login.

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
present, call `container-scan.yml` on the same `image`. When `blocking: true`
and the image is not pullable, the probe **fails closed**. When advisory, the
scan job is skipped.

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

`containerdevops-security.yml` uses this reusable for digest-pinned
`ghcr.io/pirlruc/ci-container:6.0.7@sha256:9cecca568d67dfe3debad6431153accf7fb466e08f2b97f08950b3018affe1d9` (CI-026; do not
float `:latest`). Callers pin a released SHA of this file.

## container-publish.yml

| Input | Default |
|-------|---------|
| `image_name` | required |
| `source_image` | `""` (`ghcr.io/…@sha256:…` from build; empty rebuilds from Dockerfile) |
| `rebuild` | `false` (set true to ignore `source_image` and rebuild) |
| `dockerhub_image` | `""` (set to `namespace/name` to push Hub) |
| `platforms` | `linux/amd64,linux/arm64` |
| `sign` | `false` |
| `tag_latest` | `false` (needed on **release** refs; `push`/`schedule`/`workflow_dispatch` on `main` enable `latest` without this) |
| `verify_platforms` | `true` (DOCKER-TEST-002 multi-arch verify after push) |
| `verify_command` | `/bin/true` (simple argv only — no shell metacharacters) |
| `structure_test_config` | `""` (optional CST config for per-platform verify; empty skips CST) |
| `image_title` | `""` (override OCI title; empty keeps metadata-action default) |
| `image_description` | `""` (override OCI description; consumer-facing, max 512 chars) |
| `image_documentation` | `""` (override OCI documentation URL) |
| `image_url` | `""` (override OCI url) |
| `image_vendor` | `""` (override OCI vendor) |
| `dockerhub_readme` | `""` (path in caller checkout pushed as Hub Overview) |
| `dockerhub_short_description` | `""` (Hub short description when readme is set) |
| `tag_suffix` | `""` (e.g. `-alpine`, `-debian`; empty = legacy unsuffixed tags only) |
| `tag_alias_unsuffixed` | `true` (when `tag_suffix` is set, also publish the unsuffixed tag set) |

`docker/metadata-action` uses `flavor: latest=false` so only explicit
`type=raw,value=latest` rules apply. Alpine owns unsuffixed `latest`.

When `source_image` is set and `rebuild` is false, publish **retags** that
digest onto GHCR/Hub (`docker buildx imagetools create`). That is the default
for `ci-container-image.yml` so the scanned digest is what ships.

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

**`latest` tag:** the reusable enables `latest` when `tag_latest` is true **or**
when `github.ref_name == main` on `push`, `schedule`, or `workflow_dispatch`.
Do not key this on the event's default-branch field — that payload is empty on
`schedule`, so monthly CI-027 rebuilds would silently skip `latest`. Callers
pass `tag_latest: true` only on non-prerelease **release** events (tag refs are
not branch refs). Date tags (`YYYYMMDD`) still require the explicit input.

Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` when Hub enabled **or** when
the Dockerfile pulls from `dhi.io`. Optional `ghcr_token` for private GHCR
pulls. The publish job logs in to `dhi.io` only when `dhi_login` is true
(in addition to GHCR / Hub push logins). Permissions: `packages: write`,
`id-token: write` and `attestations: write` (provenance via
`actions/attest-build-provenance` when `sign: true`). Keep `sign: false` on
private Free-plan repos, where that API is unavailable.

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

Guardrails 1.9.0 names two KICS queries that may be ignored **per service**, not
per file, when the matching compose rule already holds:

| Query | When a per-service ignore is enough |
|-------|--------------------------------------|
| `698ed579` | One-shot service (`restart: "no"`, dependents use `service_completed_successfully`) — DOCKER-COMPOSE-002 |
| `ce76b7d0` | `cap_drop: [ALL]` is already set — DOCKER-COMPOSE-005 |

Do not put those IDs in a file-wide `exclude-queries` list.

When `compose_files` is set, `scripts/check-compose-gates.sh` also enforces
measurable DOCKER-COMPOSE rules (digest-pinned images, healthcheck, privileged
cap, port bind, memory limits). Unmeasurable rules (bind-mount comments, volume
backup docs) stay documented here.

`KICS_IMAGE` is a digest-pinned workflow env (`checkmarx/kics@sha256:…`), not a
Dockerfile `FROM` and not a GitHub Action. Dependabot cannot manage it (docker
ecosystem watches `/docker/ci-container` only). Refresh the pin in
`container-iac.yml` when Checkmarx publishes a new image tag; see the comment in
`.github/dependabot.yml` (CDO-WF-004-T3).

## container-devcontainer.yml

| Input | Default |
|-------|---------|
| `dockerfile` | `.devcontainer/Dockerfile` (used when `dockerfiles` is empty) |
| `dockerfiles` | `""` (newline-separated; devcontainer and Molecule fixtures) |
| `working_directory` | `.` |
| `structure_test_config` | `""` (skip when empty) |
| `scripts_ref` | `""` |
| `runner_image` | `""` (host install when empty) |
| `blocking` | `false` |

Lints the devcontainer Dockerfile (hadolint) and optionally runs
container-structure-test when `structure_test_config` is set.

## container-handoff-cleanup.yml

Deletes a GHCR package **version** only when its tags are solely the ephemeral
`ci-run-*` tag. Call it when the run did not publish. **Never** call after a
successful publish retag — that digest also carries `{{version}}` / `latest`.
A 404 (package never created) is success. Any other API error fails the job.

## artifact-sweep.yml

Scheduled / `workflow_dispatch` job that deletes leftover `container-image*`
Actions artifacts and `docker/build-push-action` build records (`*.dockerbuild`).
Does not delete GHCR packages or scan-result artifacts.
