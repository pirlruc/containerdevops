# Changelog

All notable changes to this repository are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [6.0.8] - 2026-10-01

### Changed

- Write 6.0.7 alpine and debian digests into Hub and Packages pages. Tag only.
  No GitHub Release, so the image is not republished.

## [6.0.7] - 2026-10-01

### Changed

- `CI_BASE` is ci-lint **5.2.4**. That Debian base ships OpenSSL `deb13u3`,
  and the Alpine base keeps the refreshed gitleaks donor.
- The ci-container Dockerfiles no longer say ci-lint 5.1.1 still vendors
  PyJWT 2.13.0. ci-lint 5.2.x already installs PyJWT 2.14.0 and urllib3 2.8.0.

## [6.0.6] - 2026-09-30

### Changed

- Write 6.0.5 alpine and debian digests into Hub and Packages pages. Tag only.
  No GitHub Release, so the image is not republished.

## [6.0.5] - 2026-09-30

### Changed

- `CI_BASE` is ci-lint **5.2.2**. The Alpine base has no HIGH or CRITICAL OS
  findings. Debian openssl HIGH remains in the newest DHI digest.


## [6.0.4] - 2026-09-30

### Changed

- Hub, Packages, and workflow examples cite ci-container 6.0.2. Tag only.
  No GitHub Release, so the image is not republished.

## [6.0.3] - 2026-09-30

### Changed

- Write 6.0.2 alpine and debian digests into Hub and Packages pages. Tag only.
  No GitHub Release, so the image is not republished.


## [6.0.2] - 2026-09-30

### Changed

- `CI_BASE` is ci-lint **5.2.0** alpine and debian digests.
- Nested commondevops pin is **5.2.0**
  (`202582e7aab49d2f7c9d4bd9a6ec5e319d0c95b3`).

## [6.0.1] - 2026-09-30

### Fixed

- Publish requests `attestations: write`. The 6.0.0 release push reached the
  registry and then failed to persist the public-repo provenance attestation.

## [6.0.0] - 2026-09-30

### Breaking

- Removed `upload_image_artifact` and `image_artifact`. Scan a GHCR digest, or
  set `push_handoff: false` and `scan_local: true` on `container-build` to scan
  a local tag without a registry write (CDO-LOCAL-001).

### Added

- `container-lint` and `container-devcontainer` accept a newline-separated
  `dockerfiles` list. Hadolint still uses `hadolint_failure_threshold`.
- `container-scan` input `scanners` defaults to `vuln,secret` (DOCKER-SEC-005).
- Token-free `lint-dependabot` job (actionlint, shellcheck, hadolint, zizmor)
  so a Dependabot pull request is not only the `pins` job.
- Deviations CI-032 and REL-PUB-004 (CDO-PIN-019). The repository is going
  private again; branch protection and tag Environments are not available then.

### Changed

- `docs/guardrails` tag **1.9.0** (`16a2c95c…`); `.github/scaffold` tag **1.8.0**
  (`ac9059fd…`). Decision links cite methodologies **1.8.0**.
- CI-024 skips use `github.event.pull_request.user.login`, not `github.actor`.
  `push` stays on `main` (not `dependabot/**`).
- `FROM ${ARG}` bases are age-checked. `BUILD_ARGS` overrides the Dockerfile default.
- Handoff cleanup fails on API errors other than 404. `ci-run-*` tags are
  deleted on any run that did not publish, not only pull requests.
- Build-record retention is 1 day. The artifact sweep also deletes `*.dockerbuild`.
- Dependabot action bumps: setup-buildx 4.4.1, build-push 7.4.0, setup-qemu 4.4.0,
  codeql-action upload-sarif 4.38.1.

## [5.0.4] - 2026-09-15

### Changed

- Write 5.0.3 alpine/debian Hub digests into published rescan, Hub/Packages,
  and handoff. No GitHub Release (does not republish images).

## [5.0.3] - 2026-09-15

### Changed

- Nested [commondevops](https://github.com/pirlruc/commondevops) pin is **5.1.2**
  (`b3c462bed0de4f6475e6be7875c4ababd831acc6`).
- `CI_BASE` is ci-lint **5.1.1** alpine/debian Hub digests.
- Scheduled rescan pins `ci-container:5.0.0@sha256:0d4328a0…` (was 3.0.0).
  Hub / Packages target **5.0.3**; 5.0.4 writes the republished digests.

## [5.0.2] - 2026-09-15

### Fixed

- Actions skips reusable-workflow outputs that contain a secret substring.
  `image_ref=ghcr.io/<owner>/pkg@sha256:…` was dropped when `DOCKERHUB_USERNAME`
  equalled the owner, so cross-repo scan got an empty `image`. Callers must
  compose `ghcr.io/${{ github.repository_owner }}/<handoff_package>@<digest>`.
  `image_ref` is now `<pkg>@sha256:…` (no owner).

## [5.0.1] - 2026-09-14

### Fixed

- Reusable-workflow `image_ref` / `digest` outputs were empty for callers when
  the handoff step used `if: always()`. Scan then received a blank `image`.
  Handoff now runs on a successful build without `always()`, and always emits
  a `ghcr.io/owner/pkg@sha256:…` ref.

## [5.0.0] - 2026-09-14

MAJOR: GHCR digest handoff replaces the image-tar artifact; `latest` no longer races.

### Breaking

- `container-build.yml` no longer uploads `image.tar` by default. Callers must
  grant `packages: write` on the build job (CI-031) and pass
  `image: ${{ needs.build.outputs.image_ref }}` into `container-scan.yml`.
  The `image_artifact` download path remains for one major as an opt-in
  (`upload_image_artifact: true`).
- `container-publish.yml` retags the scanned digest when `source_image` is set
  (scan == ship). Dockerfile rebuild is `rebuild: true` or empty `source_image`.
- Nested commondevops pin is **5.0.0** (`bcddb5db…`). Consumers that pin this
  release transitively get that commondevops SHA.

### Fixed

- `docker/metadata-action` now sets `flavor: latest=false` so only the explicit
  `type=raw,value=latest` rules apply. Alpine owns unsuffixed `latest`.
- Build `gate-aggregate` includes `steps.build.outcome`.
- Published rescan fails closed when `blocking: true` and the image is not pullable.

### Added

- Job outputs `image_ref`, `digest`, `handoff_tag`, `handoff_package`.
- `container-handoff-cleanup.yml` deletes PR-only `ci-run-*` package versions
  (never versions that also carry release tags).
- Scheduled `artifact-sweep.yml` deletes leftover `container-image*` artifacts.
- Root CHANGELOG (REL-CHG-001).

### Changed

- Local dive fallback writes `dive-report.json` in the repo (gitignored) so
  Docker Desktop can mount it.
- Syft uses language catalogers (not Python-only) when `pkg_types: library`,
  omitting golang/binary so Grype does not fail on donor Go stdlib already
  ignored in Trivy.
- Alpine image lint runs secrets scan.

## [4.0.0] - 2026-09-14

See GitHub Release notes for 4.0.0 (guardrails 1.6.0, `size_class`, Alpine default).
