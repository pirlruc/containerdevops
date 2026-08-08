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
| Phase 1 — CDO-001…CDO-005 | Done; GitHub issues #2–#11 closed |
| Phase 2 — CDO-006 | Open (#12 epic, #13 task) |
| CDO-007 — workflow permissions | Open — authored in docs/issues.yml (not yet synced) |

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
- Private consumers must pass secret `checkout_token` (PAT / fine-grained with
  `contents:read` on this repo) into every `uses:` call. Without it, the nested
  sparse checkout of `pirlruc/containerdevops` fails with REST `Not Found`.
- Signing / provenance (`sign: true`) needs a public repo or Enterprise Cloud;
  consumers record `DOCKER-SEC-003` / `DOCKER-SEC-004` deviations while private.
- Product Dockerfiles that `FROM dhi.io/…` need Hub credentials passed into
  `container-build` / `container-publish` as `DOCKERHUB_USERNAME` /
  `DOCKERHUB_TOKEN` so the job can `docker login dhi.io` (Community DHI is free;
  auth is still required to pull).
- Sparse checkout of this repo into `_containerdevops` must include
  `scripts` and `docs/guardrails/docker` for threshold reads.
- This repo has no self-caller CI; PR checks are empty until a consumer exercises
  the reusable workflows.

## Suggested next work

1. Land `checkout_token` fix; pin consumers (gitlab-mcp first) to the new SHA.
2. CDO-007: least-privilege `permissions:` on reusable workflows (authored; sync with approval).
3. CDO-006: devcontainer lint/build verification (#12 / #13).
4. Home-assistant migration onto `container-iac` / image-scan jobs.

## Recent history

- Added optional `checkout_token` + `github.workflow_sha` on nested script
  checkouts so private callers can read this repo (2026-08-09).
- Authored CDO-007 on `feature-dependency-update-policy` (2026-08-08).
- Merged [PR #1](https://github.com/pirlruc/containerdevops/pull/1): Dependabot
  GitHub Actions group majors + CodeQL comment fix; synced issues (10 closed,
  CDO-006 left open).

*Last updated: 2026-08-09*
