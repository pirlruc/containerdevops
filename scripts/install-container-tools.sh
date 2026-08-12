#!/usr/bin/env bash
# Install pinned container tooling into $HOME/.local/bin (CI) when not present.
# Optional: INSTALL_ONLY=hadolint,actionlint  (comma-separated) to skip other tools.
#
# Tool versions are NOT Dependabot-managed (github-actions + docker only). Bump
# manually when a release note or CVE warrants it; each constant carries its
# upstream releases URL. Digests are SHA256 of the downloaded artifact for the
# pinned version — refresh them together with the version bump.
set -euo pipefail
DEST="${HOME}/.local/bin"
mkdir -p "${DEST}"
export PATH="${DEST}:${PATH}"

# https://github.com/hadolint/hadolint/releases
HADOLINT_VERSION="${HADOLINT_VERSION:-2.12.0}"
HADOLINT_SHA256="${HADOLINT_SHA256:-56de6d5e5ec427e17b74fa48d51271c7fc0d61244bf5c90e828aab8362d55010}"
# https://github.com/aquasecurity/trivy/releases
TRIVY_VERSION="${TRIVY_VERSION:-0.73.0}"
TRIVY_SHA256="${TRIVY_SHA256:-2edd39da482bb4e9831962487b68f68e3928ec3137794757f54d00383d79547b}"
# https://github.com/anchore/syft/releases
SYFT_VERSION="${SYFT_VERSION:-1.50.0}"
SYFT_SHA256="${SYFT_SHA256:-bf7b29ff57f06da30918266a0e1c2885a8f99784798d1bdb1628886aa015d788}"
# https://github.com/anchore/grype/releases
GRYPE_VERSION="${GRYPE_VERSION:-0.116.1}"
GRYPE_SHA256="${GRYPE_SHA256:-0122df7b655981abe547ad3d2190d65551dac6a2bfc80b4dc2a989b5d0587458}"
# https://github.com/wagoodman/dive/releases
DIVE_VERSION="${DIVE_VERSION:-0.13.1}"
DIVE_SHA256="${DIVE_SHA256:-0970549eb4a306f8825a84145a2534153badb4d7dcf3febd1967c706367c3d0e}"
# https://github.com/GoogleContainerTools/container-structure-test/releases
CST_VERSION="${CST_VERSION:-1.22.1}"
CST_SHA256="${CST_SHA256:-fa35e89512a8978585f76cf41397956d2e3a30c62c2ad3fb857b1597074d14ca}"
# https://github.com/sigstore/cosign/releases
COSIGN_VERSION="${COSIGN_VERSION:-2.4.3}"
COSIGN_SHA256="${COSIGN_SHA256:-caaad125acef1cb81d58dcdc454a1e429d09a750d1e9e2b3ed1aed8964454708}"
# https://github.com/rhysd/actionlint/releases
ACTIONLINT_VERSION="${ACTIONLINT_VERSION:-1.7.12}"
ACTIONLINT_SHA256="${ACTIONLINT_SHA256:-8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8}"
# https://github.com/koalaman/shellcheck/releases
SHELLCHECK_VERSION="${SHELLCHECK_VERSION:-0.10.0}"
SHELLCHECK_SHA256="${SHELLCHECK_SHA256:-6c881ab0698e4e6ea235245f22832860544f17ba386442fe7e9d629f8cbedf87}"

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(sha256sum "${file}" | awk '{print $1}')"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "error: SHA256 mismatch for ${file}" >&2
    echo "  expected: ${expected}" >&2
    echo "  actual:   ${actual}" >&2
    return 1
  fi
}
# Nested install bash -c bodies call this helper.
export -f verify_sha256

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
  verify_sha256 '${DEST}/hadolint' '${HADOLINT_SHA256}'
  chmod +x '${DEST}/hadolint'
"

install_if_missing shellcheck bash -c "
  curl -sSfL -o /tmp/shellcheck.txz \
    'https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz'
  verify_sha256 /tmp/shellcheck.txz '${SHELLCHECK_SHA256}'
  tar -xJf /tmp/shellcheck.txz -C /tmp
  cp \"/tmp/shellcheck-v${SHELLCHECK_VERSION}/shellcheck\" '${DEST}/shellcheck'
  chmod +x '${DEST}/shellcheck'
  rm -rf /tmp/shellcheck.txz \"/tmp/shellcheck-v${SHELLCHECK_VERSION}\"
"

# Direct release tarball — aqua install.sh is flaky under Actions rate limits.
install_if_missing trivy bash -c "
  curl -sSfL -o /tmp/trivy.tgz \
    'https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz'
  verify_sha256 /tmp/trivy.tgz '${TRIVY_SHA256}'
  tar -xzf /tmp/trivy.tgz -C '${DEST}' trivy
  rm -f /tmp/trivy.tgz
"

install_if_missing syft bash -c "
  curl -sSfL -o /tmp/syft.tgz \
    'https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz'
  verify_sha256 /tmp/syft.tgz '${SYFT_SHA256}'
  tar -xzf /tmp/syft.tgz -C '${DEST}' syft
  rm -f /tmp/syft.tgz
"

install_if_missing grype bash -c "
  curl -sSfL -o /tmp/grype.tgz \
    'https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz'
  verify_sha256 /tmp/grype.tgz '${GRYPE_SHA256}'
  tar -xzf /tmp/grype.tgz -C '${DEST}' grype
  rm -f /tmp/grype.tgz
"

install_if_missing dive bash -c "
  curl -sSfL -o /tmp/dive.tgz \
    'https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz'
  verify_sha256 /tmp/dive.tgz '${DIVE_SHA256}'
  tar -xzf /tmp/dive.tgz -C '${DEST}' dive
  rm -f /tmp/dive.tgz
"

install_if_missing container-structure-test bash -c "
  curl -sSfL -o '${DEST}/container-structure-test' \
    'https://github.com/GoogleContainerTools/container-structure-test/releases/download/v${CST_VERSION}/container-structure-test-linux-amd64'
  verify_sha256 '${DEST}/container-structure-test' '${CST_SHA256}'
  chmod +x '${DEST}/container-structure-test'
"

install_if_missing cosign bash -c "
  curl -sSfL -o '${DEST}/cosign' \
    'https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64'
  verify_sha256 '${DEST}/cosign' '${COSIGN_SHA256}'
  chmod +x '${DEST}/cosign'
"

install_if_missing actionlint bash -c "
  curl -sSfL -o /tmp/actionlint.tgz \
    'https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz'
  verify_sha256 /tmp/actionlint.tgz '${ACTIONLINT_SHA256}'
  tar -xzf /tmp/actionlint.tgz -C '${DEST}' actionlint
  chmod +x '${DEST}/actionlint'
  rm -f /tmp/actionlint.tgz
"

echo "Tool install complete. PATH=${PATH}"
