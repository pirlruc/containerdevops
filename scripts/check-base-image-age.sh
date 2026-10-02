#!/usr/bin/env bash
# DOCKER-BUILD-006 — fail when any final-stage FROM base image is older than max_age_days.
#
# Usage: check-base-image-age.sh <Dockerfile> <max_age_days>
# Env:   BUILD_ARGS  newline-separated KEY=value overlay (same shape as build-args).
# Requires: docker.
# Only FROM lines are checked (not COPY --from donors — those are tool pins, not bases).
# ${ARG} bases are resolved from ARG defaults, then BUILD_ARGS. Unresolved refs fail closed.
# Compatible with mawk (Ubuntu) and gawk — avoid IGNORECASE and [/] char classes.
set -euo pipefail

DOCKERFILE="${1:?Dockerfile path required}"
MAX_DAYS="${2:?max age days required}"
BUILD_ARGS="${BUILD_ARGS:-}"

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

declare -A ARGV=()
while IFS= read -r raw || [[ -n "${raw}" ]]; do
  line="${raw%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  [[ "${line}" =~ ^[Aa][Rr][Gg][[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue
  ARGV["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
done < "${DOCKERFILE}"

if [[ -n "${BUILD_ARGS}" ]]; then
  while IFS= read -r raw || [[ -n "${raw}" ]]; do
    line="${raw#"${raw%%[![:space:]]*}"}"
    [[ -z "${line}" || "${line}" == \#* || "${line}" != *=* ]] && continue
    ARGV["${line%%=*}"]="${line#*=}"
  done <<< "${BUILD_ARGS}"
fi

resolve_ref() {
  local ref="$1"
  local name val
  if [[ "${ref}" =~ ^\$\{([A-Za-z_][A-Za-z0-9_]*)\}$ ]]; then
    name="${BASH_REMATCH[1]}"
    val="${ARGV[${name}]:-}"
    if [[ -z "${val}" ]]; then
      echo "error: FROM ${ref} has no ARG default or BUILD_ARGS value" >&2
      return 1
    fi
    if [[ "${val}" =~ \$\{ ]]; then
      echo "error: FROM ${ref} resolved to another substitution '${val}'" >&2
      return 1
    fi
    printf '%s' "${val}"
    return 0
  fi
  if [[ "${ref}" == \$* ]]; then
    echo "error: unsupported FROM substitution '${ref}'" >&2
    return 1
  fi
  printf '%s' "${ref}"
}

# Final stage only. Builder FROMs are tool pins; the host docker CLI is not
# logged into dhi.io even when buildx is, so pulling them here fails closed.
mapfile -t RAW_REFS < <(
  awk '
    /^[Ff][Rr][Oo][Mm][[:space:]]/ {
      line=$0
      sub(/^[Ff][Rr][Oo][Mm][[:space:]]+/, "", line)
      sub(/[[:space:]]+[Aa][Ss][[:space:]].*$/, "", line)
      split(line, a, /[[:space:]]+/)
      ref=a[1]
      if (ref != "" && ref != "scratch") last=ref
    }
    END { if (last != "") print last }
  ' "${DOCKERFILE}"
)

if [[ ${#RAW_REFS[@]} -eq 0 ]]; then
  echo "No base image refs found in ${DOCKERFILE}; nothing to age-check"
  exit 0
fi

REFS=()
for raw in "${RAW_REFS[@]}"; do
  resolved="$(resolve_ref "${raw}")" || exit 1
  echo "FROM ${raw} -> ${resolved}"
  REFS+=("${resolved}")
done

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
