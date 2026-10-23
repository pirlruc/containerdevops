#!/usr/bin/env bash
# Boot a Compose project and tear it down (CDO-SMOKE-001, DOCKER-LINT-003).
#
# Env:
#   COMPOSE_FILES      space-separated compose files (required)
#   COMPOSE_ENV_FILES  space-separated env files passed to --env-file
#   COMPOSE_PROJECT    project name (default: compose-smoke)
# Requires: docker.
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required" >&2
  exit 1
fi

if [[ -z "${COMPOSE_FILES:-}" ]]; then
  echo "error: COMPOSE_FILES is required" >&2
  exit 2
fi

env_args=()
# shellcheck disable=SC2086
for env_file in ${COMPOSE_ENV_FILES:-}; do
  if [[ ! -f "${env_file}" ]]; then
    echo "error: env file not found: ${env_file}" >&2
    exit 2
  fi
  env_args+=(--env-file "${env_file}")
done

file_args=()
# shellcheck disable=SC2086
for compose_file in ${COMPOSE_FILES}; do
  if [[ ! -f "${compose_file}" ]]; then
    echo "error: compose file not found: ${compose_file}" >&2
    exit 2
  fi
  file_args+=(-f "${compose_file}")
done

project="${COMPOSE_PROJECT:-compose-smoke}"

cleanup() {
  docker compose --project-name "${project}" "${env_args[@]}" "${file_args[@]}" \
    down --remove-orphans --timeout 20 || true
}
trap cleanup EXIT

echo "Smoke up --wait project=${project}"
docker compose --project-name "${project}" "${env_args[@]}" "${file_args[@]}" up --wait
echo "Smoke up succeeded"
