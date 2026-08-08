# Workflows reference

All workflows: `workflow_call` + `workflow_dispatch`, `blocking` default `false`
(`ADVISORY` env + `continue-on-error` on gate steps).

## Shared inputs

| Input | Default | Meaning |
|-------|---------|---------|
| `blocking` | `false` | When true, gate failures fail the job |

## Shared secrets (private callers)

| Secret | Required | Meaning |
|--------|----------|---------|
| `checkout_token` | When caller ≠ this repo and this repo is private | PAT or fine-grained token with `contents:read` on `pirlruc/containerdevops` |

## Shared inputs (cross-repo callers)

| Input | Required | Meaning |
|-------|----------|---------|
| `scripts_ref` | Cross-repo callers | Commit/tag/branch matching the `uses: …@pin` — scripts checkout uses this. Same-repo `workflow_dispatch` falls back to `github.sha`. Do **not** use `github.workflow_sha` (that is the caller’s workflow). |

Reusable jobs sparse-checkout this repository into `_containerdevops` for scripts
and docker guardrail thresholds. The caller’s `GITHUB_TOKEN` cannot read a
different private repository, so private consumers must pass `checkout_token`.
Same-repo `workflow_dispatch` falls back to `github.token`.

## container-lint.yml

| Input | Default |
|-------|---------|
| `dockerfile` | `Dockerfile` |
| `working_directory` | `.` |
| `shell_scripts` | `""` |

## container-build.yml

| Input | Default |
|-------|---------|
| `context` | `.` |
| `dockerfile` | `Dockerfile` |
| `image_name` | `containerdevops-ci:local` |
| `structure_test_config` | `container-structure-test.yml` |
| `platforms` | `linux/amd64` |

Optional secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` — when set, the job
logs in to **`dhi.io`** before Buildx so Community Docker Hardened Image `FROM`
lines can pull. Pass the same Hub credentials used for Docker Hub publish.

Optional input: `dhi_login` (default false) — when true, log in to dhi.io using
those secrets. Do not use `secrets` in `if:` on reusable workflows.

Uploads `container-image` artifact (`image.tar`).

## container-scan.yml

| Input | Default |
|-------|---------|
| `image` | required |
| `image_artifact` | `""` (optional tarball load) |

## container-publish.yml

| Input | Default |
|-------|---------|
| `image_name` | required |
| `dockerhub_image` | `""` (set to `namespace/name` to push Hub) |
| `platforms` | `linux/amd64,linux/arm64` |
| `sign` | `false` |

Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` when Hub enabled **or** when
the Dockerfile pulls from `dhi.io`. The publish job logs in to `dhi.io` when
those secrets are present (in addition to GHCR / Hub push logins). Permissions:
`packages: write`, `id-token: write`, `attestations: write`.

## container-iac.yml

| Input | Default |
|-------|---------|
| `paths` | `.` |
| `exclude_paths` | `""` |
| `compose_files` | `""` |
| `kics_config` | `.github/kics.config` |
