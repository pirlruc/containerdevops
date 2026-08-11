# syntax=docker/dockerfile:1
# Container CI tooling image — extends commondevops ci-base with dive + structure-test.
# Build with: docker build --build-arg CI_BASE=ghcr.io/pirlruc/ci-base@sha256:<digest> ...
# Publish target: ghcr.io/pirlruc/ci-container
# KICS stays a separate digest-pinned image (container-iac.yml).
#
# CI_BASE default is :local for bootstrap; publish callers must pass a digest-pinned
# ghcr.io/pirlruc/ci-base ref (CI-026).
#
# No HEALTHCHECK: short-lived CI toolchain (CLI job container), not a supervised
# service. KICS query b03a748a-542d-44f4-bb86-9199ab4fd2d5 is excluded with rationale
# in docs/kics-exclusions.md (DOCKER-LINT-002 / DOCKER-RUN-002).

ARG CI_BASE=ghcr.io/pirlruc/ci-base:local

# hadolint ignore=DL3006
FROM ${CI_BASE}

LABEL org.opencontainers.image.title="ci-container" \
      org.opencontainers.image.description="Container CI tooling for pirlruc/containerdevops" \
      org.opencontainers.image.source="https://github.com/pirlruc/containerdevops" \
      org.opencontainers.image.licenses="MIT"

# Base may already be USER ci; switch to root for system installs.
USER root

# wagoodman/dive:v0.13.1 — digest pinned (CI-026)
COPY --from=wagoodman/dive:v0.13.1@sha256:f1886e6c32c094fc41a623c1989f5cb3e48aa766da5f0be233f911fc1d85ce10 \
  /usr/local/bin/dive /usr/local/bin/dive
# ghcr.io/googlecontainertools/container-structure-test:1.22.1 — digest pinned (CI-026)
COPY --from=ghcr.io/googlecontainertools/container-structure-test:1.22.1@sha256:710da3ca8ed29a42423315592f74f02df4e3d2ba19f1df7257bd481ea75ba5aa \
  /ko-app/container-structure-test /usr/local/bin/container-structure-test

WORKDIR /workspace
# Ensure non-root uid 1000 exists when CI_BASE predates it, then drop privileges.
# DHI / minimal bases often lack useradd — write passwd/group entries directly.
RUN if ! id -u 1000 >/dev/null 2>&1; then \
      printf 'ci:x:1000:1000::/home/ci:/bin/bash\n' >> /etc/passwd; \
      printf 'ci:x:1000:\n' >> /etc/group; \
      mkdir -p /home/ci; \
    fi; \
    chown -R 1000:1000 /workspace; \
    if [ -d /home/ci ]; then chown -R 1000:1000 /home/ci; fi
USER 1000:1000

ENTRYPOINT []
CMD ["bash"]
