# AI agent handoff — containerdevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/containerdevops/` |
| **Remote** | https://github.com/pirlruc/containerdevops |
| **Branch** | `feature-package-metadata-docs` (land on `main`) |
| **Role** | Reusable GitHub Actions for production container images + IaC + `ci-container` |
| **Type** | CI infrastructure (not an application image) |

## Scope

Owns `.github/workflows/container-{lint,build,scan,publish,iac,devcontainer}.yml`,
`ci-container-image.yml`, self-CI / security callers, `scripts/`, `templates/`, and
`docker/ci-container/`. Consumers pin `pirlruc/containerdevops@<sha|tag>`.

Shared infra/secrets/supply-chain forward to
[pirlruc/commondevops](https://github.com/pirlruc/commondevops).

## Pins (2026-08-12)

| Submodule / artifact | Pin |
|----------------------|-----|
| `docs/guardrails` | tag `1.1.0` → `6fe580c…` |
| `.github/scaffold` | `f8a6ba1…` |
| `ghcr.io/pirlruc/ci-container` | pending `2.1.0` (metadata + Hub Overview sync) |
| `ghcr.io/pirlruc/ci-lint` | pending commondevops `2.0.1` (CI_BASE default) |
| commondevops `uses:` | tag `2.0.0` → `26d7219…` |
| Release | [`2.0.0`](https://github.com/pirlruc/containerdevops/releases/tag/2.0.0) @ `aac5d88…` |

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| Phase 1 — CDO-001…CDO-005 | Done |
| CDO-006…CDO-007 | Done |
| CDO-008 — multi-ecosystem Dependabot | **Done** (T2 Insights recorded below) |
| CDO-009…CDO-015 | Done |
| CDO-016 — package metadata + registry pages | **In progress** (this branch) |

## Dependabot Insights (CDO-008-T2)

`.github/dependabot.yml` on `main` since `aac5d88` uses `multi-ecosystem-groups`
(`all-dependencies`) covering `github-actions` and `docker` (`/docker/ci-container`)
with monthly Europe/Lisbon schedule (SC-DEP-001/002/003).

Historical Dependabot PRs #19 and #20 were per-ecosystem `github-actions` groups
created **before** the multi-ecosystem shape landed; both are closed. No
`all-dependencies` PR has opened yet — next confirmation is the monthly run on the
1st. Blocker if none appears: open-PR limit from leftover Dependabot PRs (none open
today) or Insights delay after config land.

## Commands

```bash
bash scripts/check-container-local.sh --dockerfile Dockerfile --context .
./scripts/sync-container-tooling.sh /path/to/consuming-repo
docker build --build-arg CI_BASE=ci-lint:local \
  -t ci-container:local docker/ci-container
bash scripts/check-image-size.sh ci-container:local 700
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/containerdevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **Caller permissions:** document in `docs/workflows.md`. Missing `packages: read`
  on a container-build caller → **startup_failure**.
- **Size gate** uses `du -sxm /` (store-independent). Do not use `docker inspect .Size`.
- **OCI labels:** `docker/metadata-action` defaults to repo name/description. Pass
  `image_title` / `image_description` on publish or the package page leaks the repo
  description. Hub Overview needs `dockerhub_readme` + a Hub token with
  read/write/delete (admin) scope.
- **Hub Overview:** needs a Hub PAT with read/write/delete (admin). Push-only
  tokens return Forbidden; the sync step is advisory and does not fail publish.
- **ci-container** extends **ci-lint**; publish needs `ci-lint:2.0.2` first.
- Private consumers pass `scripts_token` + matching `scripts_ref`; `checkout_token` only
  for nested commondevops calls (lint secrets/infra).
- Scan stays on the host runner (`docker load`). Build/publish must not use job `container:`.
- Dependabot PRs skip CI (CI-024) — replace with a human branch so checks run.
- **Dependabot registries:** personal private repos need `registries:` wired to
  Dependabot secrets (`DEPENDABOT_GITHUB_TOKEN`, `DOCKERHUB_*`). Without them,
  updates fail with 401/403 on private submodules and reusable-workflow hosts.

## Suggested next work

1. Confirm the next monthly Dependabot `all-dependencies` PR (Insights).
2. Delete GHCR `2.0.0` versions that carried the repo description.
3. Paste Hub Overviews (or widen `DOCKERHUB_TOKEN` to admin) — sync was Forbidden.
4. Grant Actions Read on packages / keep Hub repos public.

## Tool versions in scripts/install-container-tools.sh

The nine version constants (`HADOLINT_VERSION`, `TRIVY_VERSION`, `SYFT_VERSION`,
`GRYPE_VERSION`, `DIVE_VERSION`, `CST_VERSION`, `COSIGN_VERSION`, `ACTIONLINT_VERSION`,
`SHELLCHECK_VERSION`) live only in that script and are **not tracked by Dependabot**
(CDO-008 covers `github-actions` and `docker` only). Bump them manually when a release
note or CVE advisory warrants an update; each constant will carry an inline release URL
comment (CDO-SC-001-T2) to help locate the right page.

## Recent history

- 2026-08-12: ai-reviewer pass — append CDO-WF-001 (infra: permissions gap) and CDO-SC-001 (actionlint unsigned pipe) to docs/issues.yml.
- 2026-08-12: wire Dependabot `registries:` for private git + dhi.io.
- 2026-08-12: package metadata overrides + Hub/GHCR doc split (CDO-016); release `2.1.0`.
- 2026-08-11: release `2.0.0` (workflow hygiene, ci-container on ci-lint).

*Last updated: 2026-08-12*
