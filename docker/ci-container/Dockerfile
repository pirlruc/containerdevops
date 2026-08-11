# syntax=docker/dockerfile:1
# Container CI tooling image — extends commondevops ci-base with dive + structure-test.
# Build with: docker build --build-arg CI_BASE=ghcr.io/pirlruc/ci-base@sha256:<digest> ...
# Publish target: ghcr.io/pirlruc/ci-container
# KICS stays a separate digest-pinned image (container-iac.yml).
#
# CI_BASE default is :local for bootstrap; publish callers must pass a digest-pinned
# ghcr.io/pirlruc/ci-base ref (CI-026).

ARG CI_BASE=ghcr.io/pirlruc/ci-base:local

# hadolint ignore=DL3006
FROM ${CI_BASE}

LABEL org.opencontainers.image.title="ci-container" \
      org.opencontainers.image.description="Container CI tooling for pirlruc/containerdevops" \
      org.opencontainers.image.source="https://github.com/pirlruc/containerdevops" \
      org.opencontainers.image.licenses="MIT"

# Base may already be USER ci; switch to root for system installs.
USER root

# wagoodman/dive:v0.12.0 — digest pinned (CI-026)
COPY --from=wagoodman/dive:v0.12.0@sha256:b4bbb985609f32ddfeb8a31f2cb254998fce2b95c358ad588a91a1ed138d6033 \
  /usr/local/bin/dive /usr/local/bin/dive
# ghcr.io/googlecontainertools/container-structure-test:1.19.3 — digest pinned (CI-026)
COPY --from=ghcr.io/googlecontainertools/container-structure-test:1.19.3@sha256:b9e32886c354705a083ce3f1d0818ddeda81641feaeeb8aec38969bc4a10855c \
  /ko-app/container-structure-test /usr/local/bin/container-structure-test

WORKDIR /workspace
# Ensure non-root user exists when CI_BASE predates the ci user, then drop privileges.
RUN id -u ci >/dev/null 2>&1 || useradd --create-home --uid 1000 --shell /bin/bash ci \
 && chown -R ci:ci /workspace
USER ci

ENTRYPOINT []
CMD ["bash"]
