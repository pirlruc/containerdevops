# syntax=docker/dockerfile:1
# Container CI tooling image — extends commondevops ci-lint with dive + structure-test.
# Build with: docker build --build-arg CI_BASE=ci-lint:local ...
# Publish target: ghcr.io/pirlruc/ci-container (and Docker Hub pirlruc/ci-container).
# KICS stays a separate digest-pinned image (container-iac.yml).
#
# CI_BASE default is :local for bootstrap; publish callers must pass a digest-pinned
# ghcr.io/pirlruc/ci-lint ref (CI-026).
#
# No HEALTHCHECK: short-lived CI toolchain (CLI job container), not a supervised
# service (DOCKER-RUN-002 / DOCKER-RUN-006).
# kics-scan disable=b03a748a-542d-44f4-bb86-9199ab4fd2d5


ARG CI_BASE=ghcr.io/pirlruc/ci-lint:local

# hadolint ignore=DL3006
FROM ${CI_BASE}

LABEL org.opencontainers.image.title="ci-container" \
      org.opencontainers.image.description="Short-lived CI toolchain image for container jobs: ci-lint plus dive and container-structure-test. Debian 13 variant. Non-root 1000:1000, linux/amd64." \
      org.opencontainers.image.source="https://github.com/pirlruc/containerdevops" \
      org.opencontainers.image.url="https://hub.docker.com/r/pirlruc/ci-container" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/pirlruc/ci-container" \
      org.opencontainers.image.vendor="pirlruc" \
      org.opencontainers.image.licenses="MIT"

USER root

# Exact pins (DOCKER-BUILD-004). ci-lint 5.2.x already installs PyJWT 2.14.0
# and urllib3 2.8.0; this line keeps a local :local base on the same floors.
RUN pip install --no-cache-dir 'PyJWT==2.14.0' 'urllib3==2.8.0'

# wagoodman/dive:v0.13.1 — digest pinned (CI-026). Re-confirmed 2026-09-11:
# no newer tag; latest still this digest (CDO-IMG-003).
COPY --from=wagoodman/dive:v0.13.1@sha256:f1886e6c32c094fc41a623c1989f5cb3e48aa766da5f0be233f911fc1d85ce10 \
  /usr/local/bin/dive /usr/local/bin/dive
# ghcr.io/googlecontainertools/container-structure-test:1.22.1 — digest pinned (CI-026).
# Re-confirmed 2026-09-11: no 1.23.0; latest still this digest (CDO-IMG-003).
COPY --from=ghcr.io/googlecontainertools/container-structure-test:1.22.1@sha256:710da3ca8ed29a42423315592f74f02df4e3d2ba19f1df7257bd481ea75ba5aa \
  /ko-app/container-structure-test /usr/local/bin/container-structure-test

WORKDIR /workspace
RUN if ! id -u 1000 >/dev/null 2>&1; then \
      printf 'ci:x:1000:1000::/home/ci:/bin/sh\n' >> /etc/passwd; \
      printf 'ci:x:1000:\n' >> /etc/group; \
      mkdir -p /home/ci; \
    fi; \
    chown -R 1000:1000 /workspace; \
    if [ -d /home/ci ]; then chown -R 1000:1000 /home/ci; fi
USER 1000:1000

ENTRYPOINT []
CMD ["sh"]
