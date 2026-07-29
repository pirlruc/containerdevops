#!/usr/bin/env bash
# Read a threshold key from docs/guardrails/docker/profile.thresholds.yml
set -euo pipefail
KEY="${1:?threshold key required}"
FILE="${2:-docs/guardrails/docker/profile.thresholds.yml}"
if [[ ! -f "${FILE}" ]]; then
  echo "Missing ${FILE}; init the guardrails submodule first." >&2
  exit 1
fi
# Strip inline comments after the value
grep "^${KEY}:" "${FILE}" | head -1 | awk '{print $2}' | tr -d '\r'
