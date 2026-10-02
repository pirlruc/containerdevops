# KICS query exclusions (DOCKER-LINT-002)

`.github/kics.config` no longer excludes queries globally. A finding that
cannot be fixed is disabled on the file that triggers it, with
`# kics-scan disable=<query-id>`, and the reason stays in this table.

Do not add a query id to `exclude-queries` for a whole tree.

## Exclusions

| Query ID | Query name | Severity | Why excluded (not corrected) |
|----------|------------|----------|------------------------------|
| `b03a748a-542d-44f4-bb86-9199ab4fd2d5` | [Healthcheck Instruction Missing](https://docs.kics.io/latest/queries/dockerfile-queries/b03a748a-542d-44f4-bb86-9199ab4fd2d5) | LOW | Disabled on `docker/ci-container/Dockerfile` and `Dockerfile.alpine` only (`# kics-scan disable=`). `ci-container` is a **CI toolchain image**: short-lived `docker run` / job-container invocations that execute CLI tools, not a long-running service. A `HEALTHCHECK` would probe nothing meaningful. Guardrails expect HEALTHCHECK rationale on **product** images (`DOCKER-RUN-002` / `DOCKER-RUN-006`). |

## Review

When bumping KICS or widening `iac_fail_on`, re-read this table and drop any row whose
underlying image class has changed (e.g. if `ci-container` gains a long-running entrypoint
that should be supervised).
