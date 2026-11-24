#!/bin/sh
# Local CI parity for this repository (CI-008).
# Host PATH tools first. A missing tool runs in the pinned ci-lint image.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

IMAGE="ghcr.io/pirlruc/ci-lint@sha256:3ed6d8dcbb08abf82e563630f2c1218cf0e8f33bb883ed46770e147113af48b0"

run_tool() {
	name="$1"
	shift
	if command -v "${name}" >/dev/null 2>&1; then
		echo "==> ${name} (host)"
		"$@"
		return 0
	fi
	echo "==> ${name} (docker)"
	docker run --rm -v "${ROOT}:/src" -w /src "${IMAGE}" "$@"
}

echo "==> submodule pins"
sh scripts/check-submodule-pins.sh

run_tool actionlint actionlint -color=false .github/workflows/*.yml
run_tool shellcheck shellcheck scripts/*.sh
run_tool hadolint hadolint docker/ci-container/Dockerfile docker/ci-container/Dockerfile.alpine

echo "==> docker scans"
sh scripts/check-ci-docker.sh

echo "Local CI parity finished."
