#!/usr/bin/env bash
# Hadolint one Dockerfile or a newline-separated list (DOCKER-LINT-001).
# DOCKERFILES, when set, replaces DOCKERFILE. RUNNER_IMAGE runs hadolint in docker.
set -euo pipefail

HADOLINT_THRESHOLD="${HADOLINT_THRESHOLD:?hadolint_failure_threshold is required}"
DOCKERFILE="${DOCKERFILE:-}"
DOCKERFILES="${DOCKERFILES:-}"
RUNNER_IMAGE="${RUNNER_IMAGE:-}"
WORKSPACE="${WORKSPACE:-}"
WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"

files=()
if [[ -n "${DOCKERFILES}" ]]; then
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    files+=("${line}")
  done <<< "${DOCKERFILES}"
elif [[ -n "${DOCKERFILE}" ]]; then
  files+=("${DOCKERFILE}")
else
  echo "error: set DOCKERFILE or DOCKERFILES" >&2
  exit 2
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo "error: no Dockerfiles to lint" >&2
  exit 1
fi

rc=0
for f in "${files[@]}"; do
  echo "hadolint ${f}"
  if [[ -n "${RUNNER_IMAGE}" ]]; then
    if [[ -z "${WORKSPACE}" ]]; then
      echo "error: WORKSPACE is required with RUNNER_IMAGE" >&2
      exit 2
    fi
    docker run --rm -v "${WORKSPACE}:/work:ro" -w "/work/${WORKING_DIRECTORY}" \
      "${RUNNER_IMAGE}" \
      hadolint --failure-threshold "${HADOLINT_THRESHOLD}" "${f}" || rc=1
  else
    hadolint --failure-threshold "${HADOLINT_THRESHOLD}" "${f}" || rc=1
  fi
done
exit "${rc}"
