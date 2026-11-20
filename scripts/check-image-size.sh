#!/usr/bin/env bash
# Fail if image rootfs size (MB) exceeds the org floor (DOCKER-PERF-001).
#
# Measurement: `du -sxm /` inside a disposable container. This is store-
# independent (unlike `docker image inspect .Size`, which reports uncompressed
# size on classic Docker Engine / GHA runners but a compressed value under
# containerd image-store hosts — a ~3.5x gap for the same image).
set -euo pipefail
IMAGE="${1:?image ref required}"
MAX_MB="${2:?max size MB required}"

# A distroless runtime has no shell. Export the rootfs and sum tar sizes.
mb="$(docker run --rm --entrypoint sh "${IMAGE}" -c 'du -sxm / 2>/dev/null | cut -f1' 2>/dev/null || true)"
if [[ -z "${mb}" || ! "${mb}" =~ ^[0-9]+$ ]]; then
	cid="$(docker create "${IMAGE}")"
	mb="$(docker export "${cid}" | tar -tvf - | awk '{s+=$3} END {printf "%d\n", int((s + 1048575) / 1048576)}')"
	docker rm "${cid}" >/dev/null
fi
if [[ -z "${mb}" || ! "${mb}" =~ ^[0-9]+$ ]]; then
	echo "error: could not measure rootfs size for ${IMAGE}" >&2
	exit 2
fi

echo "Image ${IMAGE} rootfs: ${mb} MB (limit ${MAX_MB} MB)"
if ((mb > MAX_MB)); then
	echo "DOCKER-PERF: image exceeds size floor ${MAX_MB} MB (application=image_max_size_mb / toolchain=ci_image_max_size_mb)" >&2
	exit 1
fi
