# KICS query exclusions (DOCKER-LINT-002)

Machine-readable list: [`.github/kics.config`](../.github/kics.config) (`exclude-queries`).
This file is the **tracked rationale** for every ID in that list — why the finding is
suppressed rather than fixed in the scanned tree.

Do not add an ID here without adding it to `.github/kics.config`, and vice versa.

## Exclusions

| Query ID | Query name | Severity | Why excluded (not corrected) |
|----------|------------|----------|------------------------------|
| `b03a748a-542d-44f4-bb86-9199ab4fd2d5` | [Healthcheck Instruction Missing](https://docs.kics.io/latest/queries/dockerfile-queries/b03a748a-542d-44f4-bb86-9199ab4fd2d5) | LOW | Applies to `docker/ci-container/Dockerfile` (and any consumer Dockerfile scanned with this config). `ci-container` is a **CI toolchain image**: short-lived `docker run` / job-container invocations that execute CLI tools, not a long-running service under an orchestrator. A `HEALTHCHECK` would either probe nothing meaningful (no daemon/listener) or invent a synthetic check that does not improve runtime safety. Guardrails expect HEALTHCHECK rationale on **product** images (`DOCKER-RUN-002` / `DOCKER-RUN-006`); for tooling images the correct response is to document the omission and exclude the query, not to add a cosmetic instruction. |

## Review

When bumping KICS or widening `iac_fail_on`, re-read this table and drop any row whose
underlying image class has changed (e.g. if `ci-container` gains a long-running entrypoint
that should be supervised).
