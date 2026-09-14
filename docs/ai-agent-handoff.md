# AI agent handoff — containerdevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/containerdevops/` |
| **Remote** | https://github.com/pirlruc/containerdevops |
| **Branch** | `feature-guardrails-16` (from `main` tag **3.1.0**) |
| **Role** | Reusable GitHub Actions for production container images + IaC + `ci-container` |
| **Type** | CI infrastructure (not an application image) |

## Scope

Owns `.github/workflows/container-{lint,build,scan,publish,iac,devcontainer}.yml`,
`container-published-rescan.yml`, `ci-container-image.yml`, self-CI / security callers,
`scripts/`, `templates/`, and `docker/ci-container/`. Consumers pin
`pirlruc/containerdevops@<sha|tag>`.

Shared infra/secrets/supply-chain forward to
[pirlruc/commondevops](https://github.com/pirlruc/commondevops).

## Pins (2026-09-14)

| Submodule / artifact | Pin |
|----------------------|-----|
| `docs/guardrails` | tag **1.6.0** → `77cf16eb…` |
| `.github/scaffold` | tag **1.5.0** → `9e04ed53…` |
| `ghcr.io/pirlruc/ci-container` (alpine, unsuffixed) | `3.0.0` → `sha256:9374acb5…` |
| `ghcr.io/pirlruc/ci-container` (debian) | `3.0.0-debian` → `sha256:2345c107…` |
| commondevops `uses:` / `scripts_ref` | tag `4.1.0` → `dcd9ca1c4eb8faedba170fef5dbecc61d7b284b3` (CI-034 lockstep) |
| `CI_BASE` (ci-lint debian) | `4.0.0-debian` digest `sha256:ed619755…` |
| `CI_BASE` (ci-lint alpine) | `4.0.0` digest `sha256:0a4691ba…` |
| `docker/setup-buildx-action` | `4.3.0` → `37fe6310…` |
| `github/codeql-action/upload-sarif` | `4.37.9` → `cdf488f5…` |
| `docker/setup-qemu-action` | `4.3.0` → `1f40c722…` |
| KICS (`container-iac.yml`) | `checkmarx/kics:v2.1.20-debian` linux/amd64 `sha256:aaf7bd61…` (re-confirmed 2026-09-11; no Hub tag for GitHub `v2.1.21`) |
| dive / CST donors | `v0.13.1` / `1.22.1` digests re-confirmed 2026-09-11 (no newer tags) |
| Release (reusables callers pin) | **3.1.0** → `622d7215f72e52c39869aa04dc69aa2f35b9b35b` |
| Release (ci-container image) | `3.0.0` (Alpine owns unsuffixed) |

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| Phase 1 — CDO-001…CDO-005 | Done |
| CDO-006…CDO-016 | Done |
| CDO-WF-001 — workflow contract / docs drift | Done |
| CDO-SC-001 — install-container-tools hardening | Done |
| CDO-SEC-001 — ignorefile opt-out + verify_command | Done |
| CDO-WF-002 — variant tagging + multi-scan uniqueness | Done (`2.3.0`) |
| CDO-IMG-001 — variant hardening / local parity | Done (`2.4.0`) |
| CDO-IMG-002 — Alpine ci-container | Done (`3.0.0`) |
| CDO-WF-003 — schedule-safe `latest` tag | Done (`3.1.0`) |
| CDO-IMG-003 — donor digest refresh | Done (`3.1.0`; re-confirmed, no donor bumps) |
| CDO-WF-004 — grype/scripts_ref/KICS drift | Done (`3.1.0`) |
| CDO-DOC-001 — workflows.md publish inputs | Done (`3.1.0`) |
| CDO-PIN-001 — guardrails 1.6.0 pin | Done (this wave) |

## Tool versions in scripts/install-container-tools.sh

The nine version constants (`HADOLINT_VERSION`, `TRIVY_VERSION`, `SYFT_VERSION`,
`GRYPE_VERSION`, `DIVE_VERSION`, `CST_VERSION`, `COSIGN_VERSION`,
`ACTIONLINT_VERSION`, `SHELLCHECK_VERSION`) live only in that script and are
**not tracked by Dependabot** (CDO-008 covers `github-actions` and `docker` only).
Bump them manually when a release note or CVE advisory warrants an update; each
constant carries an inline release URL and a matching `*_SHA256` digest — refresh
both together.

## Commands

```bash
bash scripts/check-container-local.sh \
  --dockerfile docker/ci-container/Dockerfile.alpine \
  --context docker/ci-container \
  --structure-test docker/ci-container/container-structure-test.yml \
  --size-class ci_toolchain \
  --advisory
sh scripts/check-submodule-pins.sh
docker build --build-arg CI_BASE=ci-lint:alpine-local \
  -f docker/ci-container/Dockerfile.alpine \
  -t ci-container:alpine-local docker/ci-container
bash scripts/check-image-size.sh ci-container:alpine-local 2000
# Local gates (prefer host PATH; else Docker):
docker run --rm -v "$PWD:/src:ro" -w /src --entrypoint actionlint ci-lint:alpine-local .github/workflows/*.yml
docker run --rm -v "$PWD:/src:ro" -w /src --entrypoint shellcheck ci-lint:alpine-local scripts/*.sh
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/containerdevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **Size class:** CI toolchain images pass `size_class: ci_toolchain` so
  `container-build.yml` reads `ci_image_max_size_mb` (2000, DOCKER-PERF-002).
  Do not re-record DOCKER-PERF-001 deviations for ci-container.
- **Caller permissions:** document in `docs/workflows.md` (CI-031). Missing `packages: read`
  on a container-build caller → **startup_failure**.
- **Size gate** uses `du -sxm /` (store-independent). Do not use `docker inspect .Size`.
- **ignorefile contract:** empty falls back to caller `.trivyignore.yaml`; set
  `ignorefile: none` (or `--no-ignorefile` locally) for unfiltered posture scans.
  ci-container's ignorefile lives at `docker/ci-container/.trivyignore.yaml`.
- **Multi-scan uniqueness:** when a caller runs more than one build/scan in a
  workflow, pass distinct `artifact_name`, `results_artifact`, and `sarif_category`
  or artifacts collide and SARIF uploads overwrite each other in code scanning.
- **Variant tags:** `tag_suffix` + `tag_alias_unsuffixed` — the lower-vulnerability
  variant should own unsuffixed tags; others set `tag_alias_unsuffixed: false`.
  Hub Overview sync runs only for the unsuffixed-owning variant.
- **GHA cache scope:** build uses `scope=<artifact_name>`; publish uses
  `scope=publish-<image_name><tag_suffix>` so parallel variants do not thrash.
- **verify_command** must be a simple argv (no shell metacharacters); runs via
  `--entrypoint`, not `bash -lc`.
- **OCI labels:** `docker/metadata-action` defaults to repo name/description. Pass
  `image_title` / `image_description` on publish or the package page leaks the repo
  description. Hub Overview needs `dockerhub_readme` + a Hub token with
  read/write/delete (admin) scope.
- **Hub Overview:** needs a Hub PAT with read/write/delete (admin). Push-only
  tokens return Forbidden; the sync step is advisory and does not fail publish.
- **ci-container** extends **ci-lint**; publish needs the digest-pinned `CI_BASE`.
- Private consumers pass `scripts_token` + matching `scripts_ref`; `checkout_token` only
  for nested commondevops calls (lint secrets/infra).
- Scan stays on the host runner (`docker load`). Build/publish must not use job `container:`.
- **GHCR rescan:** `container-scan.yml` logs in and `docker pull`s when `image` is a
  `ghcr.io/` ref and no artifact is loaded. Callers must grant `packages: read`.
  A probe job on another runner does not authenticate this job.
- Same-repo reusable calls stay on `uses: ./.github/workflows/…` until actionlint
  ships `$/` support (rhysd/actionlint#732). zizmor `self-repository` is ignored
  in `.github/config/zizmor.yml` for local callers (`ci-container-image`,
  `containerdevops-ci`, `containerdevops-security`, `container-published-rescan`).
- **Dependabot registries:** personal private repos need `registries:` wired to
  Dependabot secrets (`DEPENDABOT_GITHUB_TOKEN`, `DOCKERHUB_*`). Without them,
  updates fail with 401/403 on private submodules and reusable-workflow hosts.
- **Local vs Actions:** nested `workflow_call` composition cannot be exercised with
  `act` (not installed). Prefer `actionlint` + `zizmor` + disposable-container
  install tests before push; composition is verified by the PR run.
- **Size deviation:** retired. ci-container uses `ci_image_max_size_mb` (2000).
  REL-CHG-001 records no root CHANGELOG (GitHub Releases; GR-CHG-001).
- **Reusable pin vs image tag:** callers of `container-{lint,build,scan,publish}.yml`
  pin **3.1.0** (`622d7215…`) until **4.0.0** lands (`size_class`, fail-closed
  thresholds, collect-then-fail). Scheduled rescan uses digest-pinned `3.0.0`.
- **`latest` on schedule:** `container-publish.yml` uses `github.ref_name == main` plus
  event name (`push`/`schedule`/`workflow_dispatch`). Do not reintroduce the event
  default-branch field in reusable tag logic — it is empty on `schedule`. Callers pass
  `tag_latest` only on non-prerelease **release** events.
- **KICS digest:** `KICS_IMAGE` in `container-iac.yml` is a workflow env pin. Dependabot
  docker watches `/docker/ci-container` only and cannot bump env-var digests. Refresh
  manually (CDO-WF-004-T3). GitHub `checkmarx/kics` `v2.1.21` (2026-07-30) has no Hub
  image tag as of 2026-09-11; stay on `v2.1.20-debian` linux/amd64 `sha256:aaf7bd61…`.
- **Donor ignorefile:** dive `v0.13.1` and CST `1.22.1` digests re-confirmed 2026-09-11;
  no newer tags, so `.trivyignore.yaml` entries were not dropped. Next review 2026-11-11.
- **Dependabot PRs skip CI (CI-024)** — replace with a human branch so checks run.
  Do not merge Dependabot PR #82: it pins commondevops `4.0.0` (`e4e902e`) and does not
  update matching `scripts_ref` (CI-034 split). Wave E re-pins `4.1.0` instead.

## Suggested next work

1. Callers re-pin reusable workflows to tag **4.0.0** with matching `scripts_ref`
   and `size_class: ci_toolchain` for CI toolchain images.
2. Confirm the next monthly Dependabot `all-dependencies` PR (Insights).
3. Refresh donor digests / drop ignorefile entries before 2026-11-11 if dive/CST ship rebuilt images.

## Recent history

- 2026-09-14: CDO-PIN-001 — guardrails `1.6.0` + scaffold `1.5.0`; `size_class`
  (DOCKER-PERF-002) retires image-size deviations; fail-closed threshold reader
  (CI-022); collect-then-fail; compose gates; digest-pinned rescan; Dependabot
  codeql-action 4.37.9 + setup-qemu 4.3.0.
- 2026-09-12: Tagged **3.1.0** + GitHub Release. issues-sync closed CDO-WF-003/004, CDO-IMG-003, CDO-DOC-001; created CDO-PIN-001 (#111).
- 2026-09-11: Wave E on `feature-wave-e-workflows` — commondevops `4.1.0`
  (`dcd9ca1c4eb8…`) lockstep `uses:`/`scripts_ref` (CI-034; do not merge PR #82's
  `4.0.0` split pin); setup-buildx `4.3.0` + codeql-action `4.37.8`; schedule-safe
  `latest` (CDO-WF-003); grype `vuln_fail_on_severity`; `PLACEHOLDER_SHA` seed fix;
  KICS Dependabot limitation documented; donor digests re-confirmed (no bumps);
  CDO-PIN-001 filed (guardrails stays `5a7ac83`).
- 2026-09-11: Wave 4 — add `container-published-rescan.yml` (probe + nested
  `container-scan.yml`) merged as `3.0.2` (#86). Same-repo
  `containerdevops-security.yml` calls `./`. Cross-repo callers wait for a
  released SHA.
- 2026-09-11: accepted copilot ai-reviewer findings filed (PR #85). CDO-WF-003
  collision resolved: PR #83 keeps CDO-WF-003; PR #81 is CDO-WF-004.
- 2026-09-11: GHCR login+pull in `container-scan.yml` for registry rescans;
  `packages: read` on scan callers; zizmor `self-repository` ignored until
  actionlint supports `uses: $/…`. Donor ignorefile extended for 2026-09 Go
  stdlib / x/crypto CVEs (actionlint, dive, CST, gitleaks).
- 2026-08-12: CDO-IMG-002 / release `3.0.0` — Alpine `ci-container` owns unsuffixed
  tags; `bases` job for CI_BASE digests; PR build/scan; alpine size gate 900.
  Publish: alpine `sha256:9374acb5…`, debian `sha256:2345c107…`.
- 2026-08-12: CDO-IMG-001 / release `2.4.0` — per-variant GHA cache scopes, Hub
  Overview gating, structure test, ignorefile under `docker/ci-container/`,
  local dive/age gates, DOCKER-PERF-001 deviation.
- 2026-08-12: release `2.3.1` — CI_BASE → ci-lint `3.0.0` (#74), guardrails bump (#75).
- 2026-08-12: #74 re-pin CI_BASE to ci-lint `3.0.0`; #75 bump guardrails past ci-base drop.
- 2026-08-12: CDO-WF-002 / release `2.3.0` — artifact/SARIF uniqueness, variant
  `tag_suffix` contract, fix always-true blocking, drop ci-base comment on
  container-lint.
- 2026-08-12: CDO-WF-001 / CDO-SC-001 / CDO-SEC-001 — scan ignorefile opt-out,
  actionlint tarball + SHA256 installs, dive crash handling, commondevops pin
  `2.0.2`, workflows.md drift fix, verify_command hardening.
- 2026-08-12: wire Dependabot `registries:` for private git + dhi.io.
- 2026-08-12: package metadata overrides + Hub/GHCR doc split (CDO-016); release `2.1.0`.
- 2026-08-11: release `2.0.0` (workflow hygiene, ci-container on ci-lint).

*Last updated: 2026-09-14*
