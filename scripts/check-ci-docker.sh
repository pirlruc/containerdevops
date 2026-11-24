#!/bin/sh
# Workflow and secret scans that the host may not have, inside ci-lint.
# POSIX sh. CI-008.
#
# Usage: sh scripts/check-ci-docker.sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

IMAGE="${CONTAINERDEVOPS_CI_IMAGE:-ghcr.io/pirlruc/ci-lint@sha256:3ed6d8dcbb08abf82e563630f2c1218cf0e8f33bb883ed46770e147113af48b0}"

if ! command -v docker >/dev/null 2>&1; then
	echo "docker is required" >&2
	exit 1
fi

run() {
	echo "==> $1"
	docker run --rm -v "${ROOT}:/src" -w /src "${IMAGE}" "$@"
}

run zizmor --min-severity=low -c .github/config/zizmor.yml .github/workflows
# yamllint has no repo config here. Report it and do not fail the gate.
if [ -f .yamllint.yml ]; then
	run yamllint -c .yamllint.yml .github/workflows docs
else
	run yamllint .github/workflows || echo "yamllint reported findings; no repo config, not a gate"
fi
# --no-git: the ci-lint image used here has no git binary.
if [ -f .gitleaks.toml ]; then
	run gitleaks detect --no-git --source . --redact --config .gitleaks.toml
else
	run gitleaks detect --no-git --source . --redact
fi
echo "Docker CI scans finished."
