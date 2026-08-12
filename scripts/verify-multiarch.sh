#!/usr/bin/env bash
# DOCKER-TEST-002 — verify each published platform in a multi-arch image.
#
# Usage:
#   verify-multiarch.sh <image_ref> <platforms_csv> [verify_command] [structure_test_config]
#
# image_ref should include digest when possible (name@sha256:…).
# verify_command defaults to `true` (smoke: container starts).
# structure_test_config optional path; runs container-structure-test per platform when set.
set -euo pipefail

IMAGE="${1:?image ref required}"
PLATFORMS_CSV="${2:?platforms csv required}"
VERIFY_CMD="${3:-/bin/true}"
CST_CONFIG="${4:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required" >&2
  exit 2
fi

# Harden against shell injection from the verify_command workflow input.
# Allow a simple argv (executable + optional args); reject metacharacters.
if [[ "${VERIFY_CMD}" == *$'\n'* ]] || [[ "${VERIFY_CMD}" =~ [\;\|\&\$\`\(\)\<\>] ]] \
  || [[ "${VERIFY_CMD}" == *'{'* ]] || [[ "${VERIFY_CMD}" == *'}'* ]]; then
  echo "error: verify_command must be a simple argv (no shell metacharacters): ${VERIFY_CMD}" >&2
  exit 2
fi
# shellcheck disable=SC2206  # intentional word-split of validated argv
VERIFY_ARGV=(${VERIFY_CMD})
if [[ ${#VERIFY_ARGV[@]} -eq 0 ]]; then
  echo "error: verify_command is empty" >&2
  exit 2
fi

IFS=',' read -ra PLATFORMS <<< "${PLATFORMS_CSV}"

echo "Asserting platforms for ${IMAGE}"
RAW="$(docker buildx imagetools inspect "${IMAGE}" --raw)"
# Single-platform buildx pushes are image manifests (config+layers), not OCI
# indexes — there is no manifests[]. Platform correctness is asserted by the
# per-platform smoke runs below.
if ! printf '%s' "${RAW}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
sys.exit(0 if (data.get('manifests') or []) else 1)
"; then
  echo "  single-platform image manifest (not an index); skipping list assert"
else
  MISSING=0
  for p in "${PLATFORMS[@]}"; do
    p="$(echo "${p}" | xargs)"
    [[ -z "${p}" ]] && continue
    os="${p%%/*}"
    arch="${p#*/}"
    arch="${arch%%/*}"
    variant=""
    if [[ "${p}" == */*/* ]]; then
      variant="${p##*/}"
    fi
    if ! printf '%s' "${RAW}" | python3 -c "
import json, sys
want_os, want_arch, want_variant = sys.argv[1:4]
data = json.load(sys.stdin)
manifests = data.get('manifests') or []
for m in manifests:
    plat = m.get('platform') or {}
    if plat.get('os') != want_os or plat.get('architecture') != want_arch:
        continue
    if want_variant and plat.get('variant') != want_variant:
        continue
    if not want_variant and plat.get('variant') not in (None, '', 'v8'):
        # allow missing variant for arm64
        if want_arch == 'arm64' and plat.get('variant') in (None, '', 'v8'):
            sys.exit(0)
        continue
    sys.exit(0)
sys.exit(1)
" "${os}" "${arch}" "${variant}"; then
      echo "error: platform ${p} missing from manifest list — DOCKER-TEST-002" >&2
      MISSING=1
    else
      echo "  ok: ${p} present in manifest list"
    fi
  done

  if [[ "${MISSING}" -ne 0 ]]; then
    exit 1
  fi
fi

FAILED=0
for p in "${PLATFORMS[@]}"; do
  p="$(echo "${p}" | xargs)"
  [[ -z "${p}" ]] && continue
  echo "Smoke run --platform ${p}: ${VERIFY_CMD}"
  # Run via --entrypoint argv (no shell) after metacharacter validation above.
  if ! docker run --rm --platform "${p}" --entrypoint "${VERIFY_ARGV[0]}" "${IMAGE}" "${VERIFY_ARGV[@]:1}"; then
    echo "error: smoke run failed on ${p}" >&2
    FAILED=1
    continue
  fi
  if [[ -n "${CST_CONFIG}" ]]; then
    if [[ ! -f "${CST_CONFIG}" ]]; then
      echo "error: structure_test_config missing: ${CST_CONFIG}" >&2
      FAILED=1
      continue
    fi
    if ! command -v container-structure-test >/dev/null 2>&1; then
      echo "error: container-structure-test not on PATH" >&2
      FAILED=1
      continue
    fi
    echo "container-structure-test --platform ${p}"
    # Pull/platform-specific local tag for CST
    LOCAL_TAG="cst-verify:${p//\//-}"
    docker pull --platform "${p}" "${IMAGE}"
    docker tag "${IMAGE}" "${LOCAL_TAG}"
    if ! container-structure-test test --image "${LOCAL_TAG}" --config "${CST_CONFIG}"; then
      echo "error: structure-test failed on ${p}" >&2
      FAILED=1
    fi
  fi
done

exit "${FAILED}"
