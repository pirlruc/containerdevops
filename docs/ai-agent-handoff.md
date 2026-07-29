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

## Commands

```bash
bash scripts/check-container-local.sh --dockerfile Dockerfile --context /path/to/app
./scripts/sync-container-tooling.sh /path/to/consuming-repo
```

## Known pitfalls

- Private reusable workflows need Actions access_level `user` on this repo
  (and callers) under a User account.
- Signing / provenance (`sign: true`) needs a public repo or Enterprise Cloud;
  consumers record `DOCKER-SEC-003` / `DOCKER-SEC-004` deviations while private.
- Sparse checkout of this repo into `_containerdevops` must include
  `scripts` and `docs/guardrails/docker` for threshold reads.

## Suggested next work

1. Land first push establishing `main`; run `setup-issue-scaffold.sh`.
2. Wire gitlab-mcp thin caller + release publish.
3. CDO-006: devcontainer lint/build verification.
4. Home-assistant migration onto `container-iac` / image-scan jobs.

*Last updated: 2026-07-29*
