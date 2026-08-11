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

## Pins (2026-08-11)

| Submodule / artifact | Pin |
|----------------------|-----|
| `docs/guardrails` | tag `1.1.0` → `6fe580c…` (deinit'd) |
| `.github/scaffold` | `f8a6ba1…` (deinit'd) |
| `ghcr.io/pirlruc/ci-container` | `:1.0.1` (pre-2.0.0); rebase onto `ci-lint` for 2.0.0 |
| commondevops `uses:` | tag `1.0.0` → `a504555c…` (bump after commondevops 2.0.0) |
| `ghcr.io/pirlruc/ci-lint` | pending 2.0.0 publish (replaces ci-base as CI_BASE) |
| Release | [`1.0.1`](https://github.com/pirlruc/containerdevops/releases/tag/1.0.1) @ `e673165f…` |

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| Phase 1 — CDO-001…CDO-005 | Done |
| CDO-006…CDO-007 | Done |
| CDO-008 — multi-ecosystem Dependabot | T1 done; **T2 Insights still open** |
| CDO-009…CDO-015 | Done (duplicate CDO-015 block removed from issues.yml) |

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
  on a container-build caller → **startup_failure** (seen on commondevops CI Base Image).
- **Size gate** uses `du -sxm /` (store-independent). Do not use `docker inspect .Size`.
- **ci-container** extends **ci-lint** (not ci-base) for 2.0.0; publish needs ci-lint first.
- Private consumers pass `scripts_token` + matching `scripts_ref`; `checkout_token` only
  for nested commondevops calls (lint secrets/infra).
- Scan stays on the host runner (`docker load`). Build/publish must not use job `container:`.
- Submodules deinitialized; hydrate before sync-templates.
- Dependabot PRs skip CI (CI-024) — replace with a human branch so checks run.

## Suggested next work

1. Land hygiene + action bumps; close Dependabot PR #20 with pointer.
2. After commondevops publishes ci-lint 2.0.0, pin digest in ci-container-image.yml and cut 2.0.0.
3. Confirm Dependabot Insights (CDO-008-T2).
4. Grant Actions Read on new packages / Hub repos.

## Recent history

- 2026-08-11: workflow hygiene (permissions docs, size gate, ignorefile input,
  unused checkout_token removed, templates completed, ci-container on ci-lint).
- 2026-08-11: release `1.0.1`; published `ci-container:1.0.1`.

*Last updated: 2026-08-11*
