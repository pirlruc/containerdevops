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
`scripts/`, `templates/`, and `docker/ci-container/`. Consumers pin
`pirlruc/containerdevops@<sha>`.

Shared infra/secrets/supply-chain categories forward to
[pirlruc/commondevops](https://github.com/pirlruc/commondevops) once that repo has a
published SHA.

Guardrails pack: [docker/](https://github.com/pirlruc/guardrails/tree/main/docker).

## Pins (2026-08-10)

| Submodule / artifact | Pin |
|----------------------|-----|
| `docs/guardrails` | tag `1.0.0` → `925b9f32659936382c67850ec125a182261710bf` |
| `.github/scaffold` | `0db5890f808e4a9b9d11eabfc9a95b2b90898fad` |
| `ghcr.io/pirlruc/ci-container` | local tag `:local`; workflows use `:latest` until publish |
| commondevops `uses:` | **`74695e83a7b79784ee81fd970d9051d8efd711e8`** — replace after first commondevops push |

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| Phase 1 — CDO-001…CDO-005 | Done |
| CDO-006 — `container-devcontainer.yml` | Done (authored; hadolint + structure-test stub) |
| CDO-007 — CI-025 permissions | Done (authored) |
| CDO-008 — multi-ecosystem Dependabot | Open (config rewritten; Insights after default-branch land) |
| CDO-009 — ai-reviewer pass | Open |
| DOCKER-BUILD-006 / DOCKER-TEST-002 | Deviations in `docs/guardrail-deviations.yml` |

## Commands

```bash
bash scripts/check-container-local.sh --dockerfile Dockerfile --context /path/to/app
./scripts/sync-container-tooling.sh /path/to/consuming-repo
# Local CI image (already built on this host as :local):
docker build -t ghcr.io/pirlruc/ci-container:local docker/ci-container
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/containerdevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- **`74695e83a7b79784ee81fd970d9051d8efd711e8`** in `container-lint.yml` (infra + secrets jobs) must be
  replaced with the first published commondevops commit; keep `scripts_ref` in lockstep.
- Private reusable workflows need Actions access_level `user` on this repo (and callers).
- Private consumers must pass `checkout_token` + matching `scripts_ref`.
- **Scan stays on the host runner** (needs `docker load` for `image_artifact`); lint /
  devcontainer use `container: ghcr.io/pirlruc/ci-container:latest`.
- Build/publish must **not** use job `container:` (buildx/docker daemon).
- Signing / provenance (`sign: true`) needs a public repo or Enterprise Cloud.
- DHI pulls need `DOCKERHUB_*` + CI-024 Dependabot skip on login steps.

## Suggested next work

1. Land first commit on [commondevops](https://github.com/pirlruc/commondevops); replace
   `74695e83a7b79784ee81fd970d9051d8efd711e8` here and re-pin consumers.
2. Publish `ghcr.io/pirlruc/ci-container:latest` from `docker/ci-container`.
3. Merge this branch; confirm Dependabot Insights one-PR grouping (CDO-008-T2).
4. Cheap follow-ups for DOCKER-BUILD-006 / DOCKER-TEST-002 (or keep deviations).

## Recent history

- Phase 3–4 ops alignment on `feature-dependency-update-policy` (2026-08-10): submodule
  bumps, CI-025, commondevops placeholders, ci-container image path, Dependabot rewrite,
  CDO-006 workflow, deviations for multi-arch / base-image age.

*Last updated: 2026-08-10*
