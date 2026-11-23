#!/bin/sh
# Workflow and secret scans that the host may not have, inside ci-lint.
# POSIX sh. CI-008.
#
# Usage: sh scripts/check-ci-docker.sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

IMAGE="${CONTAINERDEVOPS_CI_IMAGE:-ghcr.io/pirlruc/ci-lint@sha256:207ab77b5ced7d067cb03f7ad6a135a30cf60dfc4a0ed417f61589a7f3d48fc0}"

if ! command -v docker >/dev/null 2>&1; then
	echo "docker is required" >&2
	exit 1
fi

run() {
	echo "==> $1"
	docker run --rm -v "${ROOT}:/src" -w /src "${IMAGE}" "$@"
}

run zizmor --min-severity=low -c .github/config/zizmor.yml .github/workflows
if [ -f .yamllint.yml ]; then
	run yamllint -c .yamllint.yml .github/workflows docs
else
	run yamllint .github/workflows
fi
if [ -f .gitleaks.toml ]; then
	run gitleaks detect --source . --redact --config .gitleaks.toml
else
	run gitleaks detect --source . --redact
fi
echo "Docker CI scans finished."
