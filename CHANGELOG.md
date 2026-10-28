# Changelog

All notable changes to this repository are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [6.3.6] - 2026-10-28

### Fixed

- Dependabot pull requests run scaffold and doc verify. Those jobs pass
  `DEPENDABOT_GITHUB_TOKEN` as `checkout_token`. Actions runs pass
  `COMMONDEVOPS_READ_TOKEN`.
- Vulnerability reports go to the GitHub security advisory form.

### Changed

- commondevops callers pin tag 5.6.2
  (`b85f95bbac8ba7d82eb90d1d84d1b8d1e8590a12`). `scripts_ref` matches.
  Job containers use the 5.6.1 linux/amd64 manifests. ci-lint Debian
  `sha256:f9001c4c8726f72107545094237d4fc0592baca023cfa299a532634666d88111`.
  ci-lint Alpine
  `sha256:207ab77b5ced7d067cb03f7ad6a135a30cf60dfc4a0ed417f61589a7f3d48fc0`.
  ci-supply-chain Debian
  `sha256:dc83deb4465d5989a03b14ccabef46c3f3426231048b962c69b8e434a7200d48`.
  Tags `6.3.3` through `6.3.5` stay put. No image republish.

## [6.3.5] - 2026-10-27

### Fixed

- A called reusable no longer joins the dispatch concurrency group just
  because the caller was `workflow_dispatch`. Sibling jobs were cancelling
  each other. Direct dispatch of the reusable still cancels its own
  previous run.

## [6.3.4] - 2026-10-27

### Fixed

- Scheduled security and published-image rescan grant `actions: read`.
  The SARIF upload job requests that scope, and GitHub rejects the
  caller at startup when the grant is missing.
- Self-CI zizmor loads `.github/config/zizmor.yml`, so the
  `self-repository` ignore applies.

### Changed

- SARIF upload is its own job. Scan and IaC jobs no longer hold
  `security-events: write`. IaC artifacts keep one day.
- Advisory scan-posture jobs scan `os,library` with ignores off.
- Pin github-scaffold **1.10.2** (`c8eddcfb`). OCI description annotations
  were already written on the index and the manifest.
- commondevops callers pin 5.4.4 (`4a7c8c43`).

## [6.3.2] - 2026-10-23

### Changed

- Pin guardrails **1.13.1** (`1945211a`). No Kotlin consumer. Existing
  caller SHAs are unchanged.
- `container-hub-description.yml` updates the `pirlruc/ci-container` Overview
  on a push to `main` when `docs/docker-hub*.md` changes. It does not run
  on `release` and does not rebuild the image.

## [6.3.1] - 2026-10-23

### Changed

- Record the published 6.3.0 ci-container digests. Alpine still owns the
  unsuffixed tag.
- The scheduled token audit passes `GUARDRAILS_READ_TOKEN` and
  `COMMONDEVOPS_READ_TOKEN`. It does not pass a Scorecard token.

## [6.3.0] - 2026-10-23

### Added

- `container-compose-smoke.yml` runs `docker compose up --wait` and removes
  the project. Heavy stacks stay opt-in.
- Compile-image notes: minimum structure-test checks and empty vcpkg overlay
  ports. See `docs/compile-image.md`.
- Base-image age check warns 7 days before `base_image_max_age_days`.

### Changed

- Pin guardrails **1.12.0** and github-scaffold **1.10.0**.
- Callers pin commondevops **5.4.0**.
- ci-container rebuilds dive and container-structure-test on Go 1.26.10.
- `CI_BASE` is ci-lint 5.4.0 for Debian and Alpine.

## [6.2.1] - 2026-10-02

### Changed

- Record the published 6.2.0 ci-container digests. Alpine still owns the
  unsuffixed tag.
- Pin guardrails **1.10.0**.

## [6.2.0] - 2026-10-02

### Changed

- Publish always attaches BuildKit provenance (`mode=max`) and an SBOM.
  `actions/attest-build-provenance` still runs only when `sign` is true.
  SC-PROV-001 is retired.
- Image scans pass `--image-config-scanners misconfig,secret`.
- Reusable workflows set a concurrency group. Dispatch cancels an older
  dispatch. Parallel variant calls in one run do not cancel each other.
- The hadolint template no longer ignores DL3008. The HEALTHCHECK KICS
  query is disabled on the ci-container Dockerfiles, not for the whole tree.
- ci-container clears setuid and setgid bits before the structure test.
- Structure-test template and ci-container assert no setuid or setgid files.
  The check uses two `find -perm` calls so `sh -c` does not need grouping.
- ci-container rebuilds dive v0.13.1 and container-structure-test v1.22.1
  on DHI Go 1.26.8. The ignore file keeps only the module findings those
  tags still have, each with `expired_at: 2026-11-01`.
- Security calls commondevops Scorecard (advisory) and the PAT expiry audit.
  Callers pin commondevops **5.3.0**
  (`803bfe60ff30d5bbcefe7fe6e38070999a66531d`).
- `CI_BASE` is ci-lint **5.3.0**. Debian owns the unsuffixed ci-lint tag.
  Alpine ci-lint is `5.3.0-alpine`. ci-container still publishes Alpine as
  the unsuffixed tag.

## [6.1.0] - 2026-10-01

### Changed

- Build and publish write the BuildKit GHA cache only on the default branch.
  Pull request and tag runs still restore that cache (CI-004).
- The artifact sweep also deletes Actions caches on pull-request and tag refs.
  It still does not delete GHCR packages, `container-scan-*`, or
  `common-supply-chain-results`. Tag only. No GitHub Release, so the image is
  not republished.

## [6.0.9] - 2026-10-01

### Changed

- Pin `github/codeql-action/upload-sarif` to 4.38.2. Tag only. No GitHub
  Release, so the image is not republished.

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
