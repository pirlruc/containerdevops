# syntax=docker/dockerfile:1
# Container CI tooling image — extends commondevops ci-lint with dive + structure-test.
# Build with: docker build -f docker/ci-container/Dockerfile docker/ci-container
# Publish target: ghcr.io/pirlruc/ci-container (and Docker Hub pirlruc/ci-container).
# KICS stays a separate digest-pinned image (container-iac.yml).
#
# The final FROM is the ci-lint 5.6.1 linux/amd64 digest (CI-026).
#
# No HEALTHCHECK: short-lived CI toolchain (CLI job container), not a supervised
# service (DOCKER-RUN-002 / DOCKER-RUN-006).
# kics-scan disable=b03a748a-542d-44f4-bb86-9199ab4fd2d5


# dive v0.13.1 and container-structure-test v1.22.1 rebuilt on Go 1.27.
# docker/cli 29.2.1 is required by the current Trivy database. Static binaries,
# so the Alpine variant copies the same artifacts.
# The final stage is a literal digest (Scorecard Pinned-Dependencies). ci-lint 5.6.1
# linux/amd64. Debian owns the unsuffixed tag.

FROM dhi.io/golang:1.27-debian13-dev@sha256:7f62233f80de83e6388c6b7686d51b1c8d8963b6d00d622aaadaf29ab817f7e7 AS dive-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/wagoodman/dive.git \
 && git fetch --depth 1 origin fe98c8a2eb08c443a36e3cc7568078909e298433 \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "fe98c8a2eb08c443a36e3cc7568078909e298433" \
 && go get golang.org/x/crypto@v0.58.0 golang.org/x/net@v0.62.0 golang.org/x/text@v0.43.0 github.com/klauspost/compress@v1.18.7 github.com/docker/cli@v29.2.1+incompatible github.com/containerd/errdefs@v1.0.0 github.com/moby/moby/client@v0.2.2 github.com/moby/sys/atomicwriter@v0.1.0 \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/dive .

FROM dhi.io/golang:1.27-debian13-dev@sha256:7f62233f80de83e6388c6b7686d51b1c8d8963b6d00d622aaadaf29ab817f7e7 AS cst-build
WORKDIR /src
RUN git init \
 && git remote add origin https://github.com/GoogleContainerTools/container-structure-test.git \
 && git fetch --depth 1 origin 1e1bb81e5272bf616f3ee87d5e085e2f90d94917 \
 && git checkout --detach FETCH_HEAD \
 && test "$(git rev-parse HEAD)" = "1e1bb81e5272bf616f3ee87d5e085e2f90d94917" \
 && go get golang.org/x/crypto@v0.58.0 golang.org/x/net@v0.62.0 golang.org/x/text@v0.43.0 github.com/klauspost/compress@v1.18.7 github.com/containerd/containerd@v1.7.33 github.com/docker/cli@v29.2.1+incompatible github.com/containerd/errdefs@v1.0.0 github.com/moby/moby/client@v0.2.2 github.com/moby/sys/atomicwriter@v0.1.0 \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/container-structure-test ./cmd/container-structure-test

# ci-lint 5.6.1 linux/amd64
FROM ghcr.io/pirlruc/ci-lint@sha256:decbddb71ddc267958b569a53a70aaa9fc297635d99d0194268451a538b10ff8

LABEL org.opencontainers.image.title="ci-container" \
      org.opencontainers.image.description="Short-lived CI toolchain image for container jobs: ci-lint plus dive and container-structure-test. Debian 13 variant. Non-root 1000:1000, linux/amd64." \
      org.opencontainers.image.source="https://github.com/pirlruc/containerdevops" \
      org.opencontainers.image.url="https://hub.docker.com/r/pirlruc/ci-container" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/pirlruc/ci-container" \
      org.opencontainers.image.vendor="pirlruc" \
      org.opencontainers.image.licenses="MIT"

USER root

COPY --from=dive-build /out/dive /usr/local/bin/dive
COPY --from=cst-build /out/container-structure-test /usr/local/bin/container-structure-test

WORKDIR /workspace
RUN if ! id -u 1000 >/dev/null 2>&1; then \
      printf 'ci:x:1000:1000::/home/ci:/bin/sh\n' >> /etc/passwd; \
      printf 'ci:x:1000:\n' >> /etc/group; \
      mkdir -p /home/ci; \
    fi; \
    chown -R 1000:1000 /workspace; \
    if [ -d /home/ci ]; then chown -R 1000:1000 /home/ci; fi
RUN find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod a-s {} +
USER 1000:1000

ENTRYPOINT []
CMD ["sh"]
