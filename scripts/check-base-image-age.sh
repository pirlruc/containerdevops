#!/usr/bin/env bash
# DOCKER-BUILD-006 — fail when any FROM / COPY --from image is older than max_age_days.
#
# Usage: check-base-image-age.sh <Dockerfile> <max_age_days>
# Requires: docker.
set -euo pipefail

DOCKERFILE="${1:?Dockerfile path required}"
MAX_DAYS="${2:?max age days required}"

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "error: Dockerfile not found: ${DOCKERFILE}" >&2
  exit 2
fi
if ! [[ "${MAX_DAYS}" =~ ^[0-9]+$ ]]; then
  echo "error: max_age_days must be an integer, got '${MAX_DAYS}'" >&2
  exit 2
fi
if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required" >&2
  exit 2
fi

mapfile -t REFS < <(
  awk '
    BEGIN { IGNORECASE=1 }
    /^FROM[[:space:]]/ {
      line=$0
      sub(/^FROM[[:space:]]+/, "", line)
      sub(/[[:space:]]+[Aa][Ss][[:space:]].*$/, "", line)
      split(line, a, /[[:space:]]+/)
      ref=a[1]
      if (ref != "" && ref != "scratch" && ref !~ /^\$\{/) print ref
      next
    }
    /^COPY[[:space:]]+--from=/ {
      line=$0
      sub(/^COPY[[:space:]]+--from=/, "", line)
      split(line, a, /[[:space:]]+/)
      ref=a[1]
      # skip stage names (no slash, no colon, no digest)
      if (ref ~ /[\/:@]/]/ print ref
    }
  ' "${DOCKERFILE}" | sort -u
)

if [[ ${#REFS[@]} -eq 0 ]]; then
  echo "No image refs found in ${DOCKERFILE}; nothing to age-check"
  exit 0
fi

NOW_EPOCH="$(date -u +%s)"
MAX_SECONDS=$((MAX_DAYS * 86400))
FAILED=0

for ref in "${REFS[@]}"; do
  echo "Inspecting ${ref}"
  if ! docker pull --quiet "${ref}" >/dev/null 2>&1; then
    echo "warning: pull failed for ${ref}; fail-closed" >&2
    FAILED=1
    continue
  fi
  created="$(docker image inspect "${ref}" --format '{{.Created}}' 2>/dev/null || true)"
  if [[ -z "${created}" ]]; then
    echo "warning: could not resolve .Created for ${ref}; fail-closed" >&2
    FAILED=1
    continue
  fi
  created_epoch="$(date -u -d "${created}" +%s 2>/dev/null || true)"
  if [[ -z "${created_epoch}" ]]; then
    echo "warning: unparseable created='${created}' for ${ref}; fail-closed" >&2
    FAILED=1
    continue
  fi
  age=$((NOW_EPOCH - created_epoch))
  age_days=$((age / 86400))
  echo "  created=${created} age_days=${age_days} max=${MAX_DAYS}"
  if (( age > MAX_SECONDS )); then
    echo "error: ${ref} is ${age_days} days old (> ${MAX_DAYS}) — DOCKER-BUILD-006" >&2
    FAILED=1
  fi
done

exit "${FAILED}"
