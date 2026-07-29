# Workflows reference

All workflows: `workflow_call` + `workflow_dispatch`, `blocking` default `false`
(`ADVISORY` env + `continue-on-error` on gate steps).

## Shared inputs

| Input | Default | Meaning |
|-------|---------|---------|
| `blocking` | `false` | When true, gate failures fail the job |

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

Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` when Hub enabled. Permissions:
`packages: write`, `id-token: write`, `attestations: write`.

## container-iac.yml

| Input | Default |
|-------|---------|
| `paths` | `.` |
| `exclude_paths` | `""` |
| `compose_files` | `""` |
| `kics_config` | `.github/kics.config` |
