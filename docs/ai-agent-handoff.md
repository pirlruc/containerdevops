# AI agent handoff — containerdevops

## Identity

| Field | Value |
|-------|-------|
| **Folder** | `common/containerdevops/` |
| **Remote** | https://github.com/pirlruc/containerdevops |
| **Role** | Reusable GitHub Actions for production container images + IaC |
| **Type** | CI infrastructure (not an application image) |

## Scope

Owns `.github/workflows/container-{lint,build,scan,publish,iac}.yml`, `scripts/`,
and `templates/`. Consumers pin `pirlruc/containerdevops@<sha>`.

Guardrails pack: [docker/](https://github.com/pirlruc/guardrails/tree/main/docker).

## Delivery status

| Phase / epic | Status |
|--------------|--------|
| Phase 1 — CDO-001…CDO-005 | Done in `docs/issues.yml` (sync to close on GitHub) |
| Phase 2 — CDO-006 | Open (no `container-devcontainer.yml` yet) |

## Commands

```bash
bash scripts/check-container-local.sh --dockerfile Dockerfile --context /path/to/app
./scripts/sync-container-tooling.sh /path/to/consuming-repo
python3 .github/scaffold/scripts/issues-sync.py \
  --repo pirlruc/containerdevops --yaml docs/issues.yml --dry-run
```

## Known pitfalls

- Private reusable workflows need Actions access_level `user` on this repo
  (and callers) under a User account.
- Signing / provenance (`sign: true`) needs a public repo or Enterprise Cloud;
  consumers record `DOCKER-SEC-003` / `DOCKER-SEC-004` deviations while private.
- Sparse checkout of this repo into `_containerdevops` must include
  `scripts` and `docs/guardrails/docker` for threshold reads.
- This repo has no self-caller CI; PR checks are empty until a consumer exercises
  the reusable workflows.

## Suggested next work

1. After merge of [PR #1](https://github.com/pirlruc/containerdevops/pull/1): run
   `issues-sync.py` (create Phase 1/2 issues; close CDO-001…CDO-005).
2. Re-pin consumers (`gitlab-mcp`, etc.) to the post-PR #1 SHA.
3. CDO-006: devcontainer lint/build verification.
4. Home-assistant migration onto `container-iac` / image-scan jobs.

## Recent history

- Dependabot grouped GitHub Actions majors (buildx/build-push/artifact/attest/…)
  on `dependabot/github_actions/github-actions-bcac8a90aa` (PR #1); CodeQL pin
  comments corrected to `# v4.37.3`.

*Last updated: 2026-07-30*
