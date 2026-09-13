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

mb="$(docker run --rm --entrypoint sh "${IMAGE}" -c 'du -sxm / 2>/dev/null | cut -f1')"
if [[ -z "${mb}" || ! "${mb}" =~ ^[0-9]+$ ]]; then
  echo "error: could not measure rootfs size for ${IMAGE}" >&2
  exit 2
fi

echo "Image ${IMAGE} rootfs: ${mb} MB (limit ${MAX_MB} MB; measured via du -sxm /)"
if (( mb > MAX_MB )); then
  echo "DOCKER-PERF: image exceeds size floor ${MAX_MB} MB (application=image_max_size_mb / toolchain=ci_image_max_size_mb)" >&2
  exit 1
fi
