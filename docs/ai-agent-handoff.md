# AI agent handoff — containerdevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/containerdevops/` |
| **Remote** | https://github.com/pirlruc/containerdevops |
| **Branch** | `main` |
| **Role** | Reusable GitHub Actions for production container images + IaC |
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
| `docs/guardrails` | tag `1.1.0` → `6fe580c7767f992af597782559c3a3be9cc95bf8` (deinit'd; empty dir) |
| `.github/scaffold` | `f8a6ba1842eba353ddd631f2311dd754bf0f44da` (deinit'd; empty dir) |
| `ghcr.io/pirlruc/ci-container` | `:1.0.1` / `:1.0` / `:latest` → `sha256:4ef9ec3921576c9dbf1677b53dac93aec918596fe6fcff2f25de51eeed2dceb5` (private) |
| commondevops `uses:` | tag `1.0.0` → `a504555c4731ee886d2a48c4ec20d110ad9434f8` |
| `ghcr.io/pirlruc/ci-base` | `:1.0.0` (private; Actions Read for this repo) |
| Release | [`1.0.1`](https://github.com/pirlruc/containerdevops/releases/tag/1.0.1) @ `e673165f…` |

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| Phase 1 — CDO-001…CDO-005 | Done |
| CDO-006 — `container-devcontainer.yml` | Done |
| CDO-007 — CI-025 permissions | Done (T1 closed) |
| CDO-008 — multi-ecosystem Dependabot | T1 done; T2 Insights after merge |
| CDO-009 — review pass | Done → spawned CDO-010…014 |
| CDO-010 — `runner_image` bootstrap | Done |
| CDO-011 — DOCKER-BUILD-006 age gate | Done; deviation removed |
| CDO-012 — DOCKER-TEST-002 multi-arch | Done; deviation removed |
| CDO-013 — ci-container publish caller | Done |
| CDO-014 — self-CI + scheduled security | Done |
| CDO-015 — Trivy ignores + dive/CST bump | Done; `ci-container:1.0.1` published |

## Commands

```bash
bash scripts/check-container-local.sh --dockerfile Dockerfile --context /path/to/app
./scripts/sync-container-tooling.sh /path/to/consuming-repo
docker build --build-arg CI_BASE=ghcr.io/pirlruc/ci-base:latest \
  -t ghcr.io/pirlruc/ci-container:local docker/ci-container
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/containerdevops --yaml docs/issues.yml --dry-run
# Hydrate submodules when needed:
git submodule update --init && git -C docs/guardrails checkout 1.1.0
```

## Known pitfalls

- **Bootstrap:** pass `runner_image: ""` until `ghcr.io/pirlruc/ci-container` is public.
- **ci-container build** needs resolvable `CI_BASE` (after commondevops publishes ci-base).
- Private consumers must pass `checkout_token` + matching `scripts_ref`.
- **Scan stays on the host runner** (needs `docker load`); lint may use job container after publish.
- Build/publish must **not** use job `container:` (buildx/docker daemon) — CI-028.
- **Cross-repo callers** must pass `scripts_token` (contents:read on containerdevops) so
  reusable workflows can sparse-checkout `scripts/`. `checkout_token` remains for nested
  commondevops calls. Same-repo callers omit `scripts_token` (defaults to `github.token`).
- Signing / provenance (`sign: true`) needs a public repo or Enterprise Cloud.
- Submodules are **deinitialized** (bor-cpp style); hydrate before `sync-templates.sh`.
- **KICS exclusions:** IDs + why-not-fixed live in [`docs/kics-exclusions.md`](kics-exclusions.md)
  (DOCKER-LINT-002); keep in sync with `.github/kics.config` `exclude-queries`.

## Known pitfalls (GHCR)

- **Package visibility has no API.** Make public in UI:
  https://github.com/users/pirlruc/packages/container/package/ci-base
  → Package settings → Change visibility → Public.
  Same for `ci-container` after first publish.
- Preferred: keep packages private; Package settings → Manage Actions access →
  grant Read to consumer repos (`pirlruc/containerdevops` for `ci-base`, then
  consumers for `ci-container`).
- Optional: repo secret `GHCR_READ_TOKEN` (classic PAT, `read:packages`) —
  do **not** pass `COMMONDEVOPS_READ_TOKEN` as `ghcr_token` (contents:read → 403).
- After `ci-container` publishes, grant Actions Read to commondevops / app repos
  the same way (or make the package public in UI).

## Suggested next work

1. Grant Actions Read on `ci-container` to consumer repos (or UI-public), same as ci-base.
2. Finish commondevops re-pin PR to `e673165f…` / `1.0.1`.
3. Confirm Dependabot Insights (CDO-008-T2).

## Recent history

- 2026-08-11: release `1.0.1`; published `ci-container:1.0.1` / `:1.0` / `:latest`
  ([run 31521149719](https://github.com/pirlruc/containerdevops/actions/runs/31521149719)).
- 2026-08-11: CDO-015 — dive `v0.13.1` + structure-test `1.22.1`; path-scoped
  `.trivyignore.yaml` for donor binaries (review 2026-11-11).
- 2026-08-11: `ghcr_token` defaults to `github.token` after Actions package access;
  do not override with contents-only PATs.
- 2026-08-11: `container-scan.yml` honors `.trivyignore.yaml` / `.trivyignore`;
  scheduled security probes `ghcr.io/pirlruc/ci-container:latest` and skips
  rescan when the package is unpublished.
- 2026-08-11: documented KICS `exclude-queries` in `docs/kics-exclusions.md`
  (`b03a748a-542d-44f4-bb86-9199ab4fd2d5` HEALTHCHECK — tooling image, not a service).
- 2026-08-11: moved `${{ }}` out of `run:` bodies into step `env:` in
  `container-{lint,build,scan,publish,iac,devcontainer}.yml` (semgrep run-shell-injection).
- 2026-08-11: runner_image dual jobs, age/multi-arch gates, ci-container publish caller,
  self-CI/security schedules, guardrails 1.1.0 + scaffold bump, deviations cleared.

*Last updated: 2026-08-11*
