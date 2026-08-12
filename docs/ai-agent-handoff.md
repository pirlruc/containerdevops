# AI agent handoff — containerdevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/containerdevops/` |
| **Remote** | https://github.com/pirlruc/containerdevops |
| **Branch** | `main` |
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
| `docs/guardrails` | commit `5a7ac83…` (post ci-base ref drop) |
| `.github/scaffold` | `f8a6ba1…` |
| `ghcr.io/pirlruc/ci-container` | tag `2.3.1` |
| commondevops `uses:` | tag `2.0.2` → `4fd83922506d…` |
| `CI_BASE` (ci-lint) | `3.0.0` digest `sha256:a3601772…` |
| Release | `2.3.1` (CI_BASE → ci-lint `3.0.0` + guardrails `5a7ac83…`) |

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| Phase 1 — CDO-001…CDO-005 | Done |
| CDO-006…CDO-016 | Done |
| CDO-WF-001 — workflow contract / docs drift | Done |
| CDO-SC-001 — install-container-tools hardening | Done |
| CDO-SEC-001 — ignorefile opt-out + verify_command | Done |
| CDO-WF-002 — variant tagging + multi-scan uniqueness | Done (`2.3.0`) |

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
bash scripts/check-container-local.sh --dockerfile Dockerfile --context .
bash scripts/check-container-local.sh --image ci-container:local --no-ignorefile --advisory
./scripts/sync-container-tooling.sh /path/to/consuming-repo
docker build --build-arg CI_BASE=ci-lint:local \
  -t ci-container:local docker/ci-container
bash scripts/check-image-size.sh ci-container:local 700
# Local gates (prefer host PATH; else Docker):
docker run --rm -v "$PWD:/src:ro" -w /src --entrypoint actionlint ci-lint:local .github/workflows/*.yml
docker run --rm -v "$PWD:/src:ro" -w /src --entrypoint shellcheck ci-lint:local scripts/*.sh
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/containerdevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **Caller permissions:** document in `docs/workflows.md`. Missing `packages: read`
  on a container-build caller → **startup_failure**.
- **Size gate** uses `du -sxm /` (store-independent). Do not use `docker inspect .Size`.
- **ignorefile contract:** empty falls back to caller `.trivyignore.yaml`; set
  `ignorefile: none` (or `--no-ignorefile` locally) for unfiltered posture scans.
- **Multi-scan uniqueness:** when a caller runs more than one build/scan in a
  workflow, pass distinct `artifact_name`, `results_artifact`, and `sarif_category`
  or artifacts collide and SARIF uploads overwrite each other in code scanning.
- **Variant tags:** `tag_suffix` + `tag_alias_unsuffixed` — the lower-vulnerability
  variant should own unsuffixed tags; others set `tag_alias_unsuffixed: false`.
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
- Dependabot PRs skip CI (CI-024) — replace with a human branch so checks run.
- **Dependabot registries:** personal private repos need `registries:` wired to
  Dependabot secrets (`DEPENDABOT_GITHUB_TOKEN`, `DOCKERHUB_*`). Without them,
  updates fail with 401/403 on private submodules and reusable-workflow hosts.
- **Local vs Actions:** nested `workflow_call` composition cannot be exercised with
  `act` (not installed). Prefer `actionlint` + `zizmor` + disposable-container
  install tests before push; composition is verified by the PR run.

## Suggested next work

1. Confirm the next monthly Dependabot `all-dependencies` PR (Insights).
2. Paste Hub Overviews (or widen `DOCKERHUB_TOKEN` to admin) — sync was Forbidden.
3. Consumers still on `2.3.0` should move to `2.3.1` for the CI_BASE / guardrails pins.

## Recent history

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

*Last updated: 2026-08-12*
