#!/usr/bin/env bash
# Read a threshold key from a YAML profile (vendored or guardrails submodule).
# CI-022 / CI-035: missing file, missing key, or empty value fails closed.
set -euo pipefail
KEY="${1:?threshold key required}"
FILE="${2:-scripts/docker.profile.thresholds.yml}"
if [[ ! -f "${FILE}" ]]; then
  echo "Missing ${FILE}; vendor or pass an explicit thresholds path." >&2
  exit 1
fi
LINE="$(grep -E "^${KEY}:" "${FILE}" | head -1 || true)"
if [[ -z "${LINE}" ]]; then
  echo "missing threshold key '${KEY}' in ${FILE}" >&2
  exit 1
fi
# Strip inline comments after the value
VALUE="$(awk '{print $2}' <<<"${LINE}" | tr -d '\r')"
if [[ -z "${VALUE}" ]]; then
  echo "empty threshold key '${KEY}' in ${FILE}" >&2
  exit 1
fi
printf '%s\n' "${VALUE}"
