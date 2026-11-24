#!/usr/bin/env bash
# Fail if image rootfs size (MB) exceeds the org floor (DOCKER-PERF-001).
#
# Measurement runs on the host (DOCKER-PERF-003). `docker export` streams the
# rootfs and tar sums member sizes. No shell runs inside the image, so a
# runtime with no shell still passes the gate. `docker image inspect .Size`
# is not used: classic Docker Engine reports uncompressed bytes and a
# containerd image store reports compressed bytes.
set -euo pipefail
IMAGE="${1:?image ref required}"
MAX_MB="${2:?max size MB required}"

# The command is stored and never started. A scratch image has no CMD.
cid="$(docker create "${IMAGE}" /dev/null)"
cleanup() {
	docker rm "${cid}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

mb="$(docker export "${cid}" | tar -tvf - | awk '{s+=$3} END {printf "%d\n", int((s + 1048575) / 1048576)}')"
if [[ -z "${mb}" || ! "${mb}" =~ ^[0-9]+$ ]]; then
	echo "error: could not measure rootfs size for ${IMAGE}" >&2
	exit 2
fi

echo "Image ${IMAGE} rootfs: ${mb} MB (limit ${MAX_MB} MB)"
if ((mb > MAX_MB)); then
	echo "DOCKER-PERF: image exceeds size floor ${MAX_MB} MB (application=image_max_size_mb / toolchain=ci_image_max_size_mb)" >&2
	exit 1
fi
