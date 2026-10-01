# AI agent handoff — containerdevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `ops/containerdevops/` |
| **Remote** | https://github.com/pirlruc/containerdevops |
| **Branch** | `main` → tag **6.0.2** (image), **6.0.3** tag-only digests |
| **Role** | Reusable GitHub Actions for production container images + IaC + `ci-container` |
| **Type** | CI infrastructure (not an application image) |

## Scope

Owns `.github/workflows/container-{lint,build,scan,publish,iac,devcontainer}.yml`,
`container-published-rescan.yml`, `ci-container-image.yml`, self-CI / security callers,
`scripts/`, `templates/`, and `docker/ci-container/`. Consumers pin
`pirlruc/containerdevops@<sha|tag>`.

Shared infra/secrets/supply-chain forward to
[pirlruc/commondevops](https://github.com/pirlruc/commondevops).

## Pins (2026-09-30)

| Submodule / artifact | Pin |
|----------------------|-----|
| `docs/guardrails` | tag **1.9.0** → `16a2c95c…` |
| `.github/scaffold` | tag **1.8.0** → `ac9059fd…` |
| methodologies (links only; not a submodule) | tag **1.8.0** |
| `ghcr.io/pirlruc/ci-container` (alpine, unsuffixed) | `6.0.5` `sha256:09b97b6c4dfdde9f43113c1000bbae2f80aaae194725ffe1e8f1ccc8ff3204e0` (`latest` == alpine) |
| `ghcr.io/pirlruc/ci-container` (debian) | `6.0.5-debian` `sha256:38fb1ced38c9e128036a4dfdbf719ca633d6a926384f7f1d78b8d13eb628afed` |
| commondevops `uses:` / `scripts_ref` | tag `5.2.0` → `202582e7aab49d2f7c9d4bd9a6ec5e319d0c95b3` (CI-034 lockstep) |
| `CI_BASE` (ci-lint debian) | `5.2.2-debian` digest `sha256:2cb20ba2d39f55ccc4195acc162013162682cb3bcccc31c300261965ca9b30c1` |
| `CI_BASE` (ci-lint alpine) | `5.2.2` digest `sha256:fd24e836c677e044163aab19e1e7d49d92ce34576deb7970b1ae16ea52b36d1b` |
| `docker/setup-buildx-action` | `4.4.1` → `f87e5991…` |
| `docker/build-push-action` | `7.4.0` → `c3c9e263…` |
| `github/codeql-action/upload-sarif` | `4.38.1` → `1c5b6756…` |
| `docker/setup-qemu-action` | `4.4.0` → `99012661…` |
| KICS (`container-iac.yml`) | `checkmarx/kics:v2.1.20-debian` linux/amd64 `sha256:aaf7bd61…` (re-confirmed 2026-09-11; no Hub tag for GitHub `v2.1.21`) |
| dive / CST donors | `v0.13.1` / `1.22.1` digests re-confirmed 2026-09-11 (no newer tags) |
| Release (reusables callers pin) | **6.0.2** → `dedddba0782f46d645a36199fcbd74e522f7b698` |
| Release (ci-container image) | `6.0.5` (Alpine owns unsuffixed; `flavor: latest=false`) |

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
| CDO-PIN-001 — guardrails 1.6.0 pin | Done |
| CDO-PIN-018 — guardrails 1.8.0 / scaffold 1.7.0 | Done (landed before 6.0.0) |
| CDO-PIN-019 — Free-plan CI-032 / REL-PUB-004 | Done (deviations; repo returns to private) |
| CDO-LOCAL-001 — local scan without GHCR push | Done (`6.0.0`) |

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
- **Caller permissions:** document in `docs/workflows.md` (CI-031). Build callers
  need `packages: write` (ephemeral GHCR handoff). Missing that → **startup_failure**.
  Scan callers still need `packages: read` and a composed GHCR ref
  `ghcr.io/<owner>/<handoff_package>@<digest>`. Do not pass `image_ref` as a
  docker ref: Actions strips outputs that contain `DOCKERHUB_USERNAME`.
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
  `cache-to` is `type=gha,mode=min` (not `mode=max`). Leftover `container-image-*`
  Actions artifacts were deleted 2026-09-15. Do **not** delete published GHCR/Hub
  tags.
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
  Host dive fallback writes `dive-report.json` in the repo (gitignored); do not
  mount `/tmp` for the JSON on Docker Desktop.
- **Size deviation:** retired. ci-container uses `ci_image_max_size_mb` (2000).
  REL-CHG-001 is closed by root `CHANGELOG.md`. Unsigned private publish is
  recorded as SC-SIGN-001 / SC-PROV-001.
- **GHCR handoff:** do **not** delete published GHCR/Packages versions. PR
  cleanup may delete a version only when its tags are solely `ci-run-*`. After
  publish retag the same digest carries `5.0.0`/`latest` — never sweep it.
  Compose scan/publish refs from `handoff_package` + `digest`. A full
  `ghcr.io/<owner>/…` `image_ref` is secret-masked when `DOCKERHUB_USERNAME`
  equals the owner (5.0.1 left callers with an empty `image`).
- **6.0.0 handoff:** `upload_image_artifact` / `image_artifact` are gone. Scan a
  GHCR digest, or set `push_handoff: false` and `scan_local: true` on
  `container-build`. Do not bring the tar back.
- **Dependabot PRs (CI-024):** secret-backed jobs skip on
  `github.event.pull_request.user.login`, not `github.actor`. `pins` and
  `lint-dependabot` are the token-free merge signal. Do not grant Dependabot
  the org PAT.
- **`latest` on schedule:** `flavor: latest=false` plus explicit
  `type=raw,value=latest`. Alpine (`tag_alias_unsuffixed: true`) owns unsuffixed
  `latest`. Do not reintroduce metadata-action's default `latest=auto`. Callers
  pass `tag_latest` only on non-prerelease **release** events.
- **KICS digest:** `KICS_IMAGE` in `container-iac.yml` is a workflow env pin. Dependabot
  docker watches `/docker/ci-container` only and cannot bump env-var digests. Refresh
  manually (CDO-WF-004-T3). GitHub `checkmarx/kics` `v2.1.21` (2026-07-30) has no Hub
  image tag as of 2026-09-11; stay on `v2.1.20-debian` linux/amd64 `sha256:aaf7bd61…`.
- **Donor ignorefile:** dive `v0.13.1` and CST `1.22.1` digests re-confirmed 2026-09-11;
  no newer tags, so `.trivyignore.yaml` entries were not dropped. Next review 2026-11-11.

## Suggested next work

1. Callers that still pass `image_artifact` must move to 6.0.2. gitlab-mcp is the known one.
2. Refresh donor digests / drop ignorefile entries before 2026-11-11 if dive/CST ship rebuilt images.

## Recent history

- 2026-09-30: **6.0.2** — CI_BASE is ci-lint 5.2.2. Alpine
  `sha256:8acbde10296d715f02174d0825689276fbcb46186c888ecb4ede82b2110a8f1a`,
  debian `sha256:6e0df10282985ac503cee69f869f1784789735713c9c5e5f2d52070280792cd4`.
  **6.0.1** fixed provenance (`attestations: write`). **6.0.3** is tag-only digests.
- 2026-09-30: **6.0.0** — guardrails **1.9.0** / scaffold **1.8.0** / methodologies
  links **1.8.0**. Removed the image-tar handoff. `scan_local` + `push_handoff: false`
  scans without a GHCR write. Trivy scanners default `vuln,secret`. CI-024 uses
  the pull request author. Build-record retention is 1 day. CI-032 and REL-PUB-004
  recorded for the private Free plan.
- 2026-09-30: guardrails **1.8.0** / scaffold **1.7.0** on main before 6.0.0.
- 2026-09-15: **5.0.4** (tag-only) — write 5.0.3 alpine/debian Hub digests
  (`3aeed654…` / `14f26db2…`). Hub `latest` == `5.0.3` alpine.
- 2026-09-15: **5.0.3** — re-pin commondevops 5.1.2, CI_BASE ci-lint 5.1.1,
  scheduled rescan off `ci-container:3.0.0` onto 5.0.0 Hub alpine digest.
- 2026-09-15: Quota sweep — leftover `container-image-*` artifacts deleted.
  BuildKit GHA cache stays `mode=min`. No published GHCR/Hub tag delete.
- 2026-09-15: **5.0.2** — compose GHCR scan/publish refs from `handoff_package`
  + `digest`. `image_ref` with the owner is secret-masked when Hub username
  equals `github.repository_owner`.
- 2026-09-14: **5.0.1** — reusable-workflow handoff without `if: always()`
  (still insufficient: owner in `image_ref` is secret-masked).
- 2026-09-14: **5.0.0** — GHCR digest handoff (no default image tar),
  `flavor: latest=false`, CHANGELOG, SC-SIGN-001 / SC-PROV-001, 1-day scan
  artifacts, PR-only `ci-run-*` cleanup, artifact sweep.
- 2026-09-14: Tagged **4.0.0** + GitHub Release (`a29ebe54…`, #114). Callers pin
  `size_class: ci_toolchain` and matching `scripts_ref`.
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

*Last updated: 2026-09-30*
