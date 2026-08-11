# AI agent handoff — containerdevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/containerdevops/` |
| **Remote** | https://github.com/pirlruc/containerdevops |
| **Branch** | `feature-dependency-update-policy` |
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
| `ghcr.io/pirlruc/ci-container` | publish via `ci-container-image.yml` after ci-base exists |
| commondevops `uses:` | **`74695e83…`** — replace with `1.0.0` after commondevops release |

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
- Signing / provenance (`sign: true`) needs a public repo or Enterprise Cloud.
- Submodules are **deinitialized** (bor-cpp style); hydrate before `sync-templates.sh`.

## Suggested next work

1. Merge this branch; confirm Dependabot Insights (CDO-008-T2).
2. After commondevops `1.0.0` + public `ci-base`, cut containerdevops `1.0.0` release to publish ci-container.
3. Re-pin commondevops `uses:` from `74695e83…` to `1.0.0`.
4. Make `ghcr.io/pirlruc/ci-container` package public; default `runner_image` to `:latest` if desired.

## Recent history

- 2026-08-11: moved `${{ }}` out of `run:` bodies into step `env:` in
  `container-{lint,build,scan,publish,iac,devcontainer}.yml` (semgrep run-shell-injection).
- 2026-08-11: runner_image dual jobs, age/multi-arch gates, ci-container publish caller,
  self-CI/security schedules, guardrails 1.1.0 + scaffold bump, deviations cleared.

*Last updated: 2026-08-11*
