#!/usr/bin/env bash
# Install pinned container tooling into $HOME/.local/bin (CI) when not present.
# Optional: INSTALL_ONLY=hadolint,actionlint  (comma-separated) to skip other tools.
set -euo pipefail
DEST="${HOME}/.local/bin"
mkdir -p "${DEST}"
export PATH="${DEST}:${PATH}"

HADOLINT_VERSION="${HADOLINT_VERSION:-2.12.0}"
TRIVY_VERSION="${TRIVY_VERSION:-0.65.0}"
SYFT_VERSION="${SYFT_VERSION:-1.27.1}"
GRYPE_VERSION="${GRYPE_VERSION:-0.92.2}"
DIVE_VERSION="${DIVE_VERSION:-0.12.0}"
CST_VERSION="${CST_VERSION:-1.19.3}"
COSIGN_VERSION="${COSIGN_VERSION:-2.4.3}"
ACTIONLINT_VERSION="${ACTIONLINT_VERSION:-1.7.7}"

should_install() {
  local name="$1"
  local only="${INSTALL_ONLY:-}"
  if [[ -z "${only}" ]]; then
    return 0
  fi
  [[ ",${only}," == *",${name},"* ]]
}

install_if_missing() {
  local name="$1"
  shift
  if ! should_install "${name}"; then
    return 0
  fi
  if command -v "${name}" >/dev/null 2>&1; then
    echo "${name}: already on PATH ($(command -v "${name}"))"
    return 0
  fi
  echo "Installing ${name}…"
  "$@"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "error: ${name} not on PATH after install (PATH=${PATH})" >&2
    return 1
  fi
}

install_if_missing hadolint bash -c "
  curl -sSfL -o '${DEST}/hadolint' \
    'https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64'
  chmod +x '${DEST}/hadolint'
"

# Direct release tarball — aqua install.sh is flaky under Actions rate limits.
install_if_missing trivy bash -c "
  curl -sSfL -o /tmp/trivy.tgz \
    'https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz'
  tar -xzf /tmp/trivy.tgz -C '${DEST}' trivy
  rm -f /tmp/trivy.tgz
"

install_if_missing syft bash -c "
  curl -sSfL 'https://raw.githubusercontent.com/anchore/syft/main/install.sh' \
    | sh -s -- -b '${DEST}' v${SYFT_VERSION}
"

install_if_missing grype bash -c "
  curl -sSfL 'https://raw.githubusercontent.com/anchore/grype/main/install.sh' \
    | sh -s -- -b '${DEST}' v${GRYPE_VERSION}
"

install_if_missing dive bash -c "
  curl -sSfL -o /tmp/dive.tgz \
    'https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz'
  tar -xzf /tmp/dive.tgz -C '${DEST}' dive
  rm -f /tmp/dive.tgz
"

install_if_missing container-structure-test bash -c "
  curl -sSfL -o '${DEST}/container-structure-test' \
    'https://storage.googleapis.com/container-structure-test/v${CST_VERSION}/container-structure-test-linux-amd64'
  chmod +x '${DEST}/container-structure-test'
"

install_if_missing cosign bash -c "
  curl -sSfL -o '${DEST}/cosign' \
    'https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64'
  chmod +x '${DEST}/cosign'
"

install_if_missing actionlint bash -c "
  curl -sSfL 'https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash' \
    | bash -s -- '${ACTIONLINT_VERSION}' '${DEST}'
"

echo "Tool install complete. PATH=${PATH}"
