# syntax=docker/dockerfile:1
# Container CI tooling image — extends commondevops ci-base with dive + structure-test.
# Build with: docker build --build-arg CI_BASE=ghcr.io/pirlruc/ci-base@sha256:<digest> ...
# Publish target: ghcr.io/pirlruc/ci-container
# KICS stays a separate digest-pinned image (container-iac.yml).
#
# CI_BASE default is :local for bootstrap; publish callers must pass a digest-pinned
# ghcr.io/pirlruc/ci-base ref (CI-026).

ARG CI_BASE=ghcr.io/pirlruc/ci-base:local
ARG CST_VERSION=1.19.3

# DHI python-dev has no curl; fetch CST from a short-lived Ubuntu stage.
# ubuntu:24.04 — digest pinned (DOCKER-BUILD-003 / CI-026)
FROM docker.io/library/ubuntu:24.04@sha256:561618e2c15bf2397621dd04f96926663a3b5616c189cf7e38db7e82f5c538ea AS cst
ARG CST_VERSION
# Transient fetch stage; curl/ca-certificates versions float with the digest-pinned base.
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && curl -sSfL -o /container-structure-test \
      "https://github.com/GoogleContainerTools/container-structure-test/releases/download/v${CST_VERSION}/container-structure-test-linux-amd64" \
 && chmod +x /container-structure-test

# CI_BASE is digest-pinned by the publish caller (CI-026).
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
COPY --from=cst /container-structure-test /usr/local/bin/container-structure-test

WORKDIR /workspace
# Ensure non-root user exists when CI_BASE predates the ci user, then drop privileges.
RUN id -u ci >/dev/null 2>&1 || useradd --create-home --uid 1000 --shell /bin/bash ci \
 && chown -R ci:ci /workspace
USER ci

ENTRYPOINT []
CMD ["bash"]
