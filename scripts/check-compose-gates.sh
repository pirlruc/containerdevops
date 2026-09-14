#!/usr/bin/env bash
# Measurable DOCKER-COMPOSE-* gates against `docker compose config --format json`.
# Unmeasurable rules (bind-mount comments, backup docs) stay in docs/workflows.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THRESHOLDS="${ROOT}/scripts/docker.profile.thresholds.yml"
if [[ ! -f "${THRESHOLDS}" ]]; then
  echo "Missing ${THRESHOLDS}" >&2
  exit 1
fi

PRIV_MAX="$(bash "${ROOT}/scripts/read-thresholds.sh" compose_privileged_services_max "${THRESHOLDS}")"
PORT_BIND="$(bash "${ROOT}/scripts/read-thresholds.sh" compose_default_port_bind "${THRESHOLDS}")"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 COMPOSE_FILE [COMPOSE_FILE ...]" >&2
  exit 2
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required for compose gates (CI-035)" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for compose gates (CI-035)" >&2
  exit 1
fi

status=0
for f in "$@"; do
  if [[ ! -f "${f}" ]]; then
    echo "compose file not found: ${f}" >&2
    status=1
    continue
  fi
  echo "==> compose gates: ${f}"
  json="$(docker compose -f "${f}" config --format json)"

  # DOCKER-COMPOSE-001 — every service image is digest-pinned.
  while IFS= read -r img; do
    [[ -z "${img}" ]] && continue
    if [[ "${img}" != *@sha256:* ]]; then
      echo "DOCKER-COMPOSE-001: ${f} service image is not digest-pinned: ${img}" >&2
      status=1
    fi
  done < <(jq -r '.services // {} | to_entries[] | .value.image // empty' <<<"${json}")

  # DOCKER-COMPOSE-002 — long-running services declare healthcheck.
  while IFS= read -r svc; do
    [[ -z "${svc}" ]] && continue
    echo "DOCKER-COMPOSE-002: ${f} service ${svc} has no healthcheck" >&2
    status=1
  done < <(jq -r '.services // {} | to_entries[] | select(.value.healthcheck == null) | .key' <<<"${json}")

  # DOCKER-COMPOSE-005 — privileged services capped.
  priv="$(jq '[.services // {} | to_entries[] | select(.value.privileged == true)] | length' <<<"${json}")"
  if (( priv > PRIV_MAX )); then
    echo "DOCKER-COMPOSE-005: ${f} privileged services=${priv} exceeds compose_privileged_services_max=${PRIV_MAX}" >&2
    status=1
  fi

  # DOCKER-COMPOSE-006 — published ports bind to the org default interface.
  while IFS= read -r pub; do
    [[ -z "${pub}" ]] && continue
    echo "DOCKER-COMPOSE-006: ${f} published port is not bound to ${PORT_BIND}: ${pub}" >&2
    status=1
  done < <(jq -r --arg bind "${PORT_BIND}" '
      .services // {} | to_entries[] | .value.ports // [] | .[]
      | select((.published // "") != "")
      | select((.host_ip // "0.0.0.0") != $bind)
      | "\(.host_ip // "0.0.0.0"):\(.published)"
    ' <<<"${json}")

  # DOCKER-COMPOSE-007 — memory limits on long-running services.
  while IFS= read -r svc; do
    [[ -z "${svc}" ]] && continue
    echo "DOCKER-COMPOSE-007: ${f} service ${svc} has no mem_limit / deploy.resources.limits.memory" >&2
    status=1
  done < <(jq -r '
      .services // {} | to_entries[]
      | select((.value.mem_limit == null)
               and ((.value.deploy.resources.limits.memory // null) == null))
      | .key
    ' <<<"${json}")
done

exit "${status}"
