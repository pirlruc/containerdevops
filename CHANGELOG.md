# Changelog

All notable changes to this repository are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

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
