#!/usr/bin/env bash
# Read a threshold key from scripts/docker.profile.thresholds.yml (vendored; keep in sync with guardrails docker pack)
set -euo pipefail
KEY="${1:?threshold key required}"
FILE="${2:-scripts/docker.profile.thresholds.yml}"
if [[ ! -f "${FILE}" ]]; then
  echo "Missing ${FILE}; init the guardrails submodule first." >&2
  exit 1
fi
# Strip inline comments after the value
grep "^${KEY}:" "${FILE}" | head -1 | awk '{print $2}' | tr -d '\r'
