#!/usr/bin/env bash
# Fail if docker image size (MB) exceeds the org floor.
set -euo pipefail
IMAGE="${1:?image ref required}"
MAX_MB="${2:?max size MB required}"
bytes="$(docker image inspect "${IMAGE}" --format '{{.Size}}')"
mb=$((bytes / 1024 / 1024))
echo "Image ${IMAGE} size: ${mb} MB (limit ${MAX_MB} MB)"
if (( mb > MAX_MB )); then
  echo "DOCKER-PERF-001: image exceeds image_max_size_mb=${MAX_MB}" >&2
  exit 1
fi
