#!/usr/bin/env bash
# Local CI parity for container gates (CI-008).
# Host PATH tools preferred; missing tools run via digest-pinned images.
#
# Resolution table (host → Docker fallback, digest-pinned CI-026):
# | Tool                      | Host preferred     | Docker fallback                         |
# |---------------------------|--------------------|-----------------------------------------|
# | hadolint                  | hadolint           | hadolint/hadolint:2.12.0-alpine@sha256:3c206a45… |
# | trivy                     | trivy              | aquasec/trivy:0.73.0@sha256:7cced7ca…   |
# | dive                      | dive               | wagoodman/dive:v0.13.1@sha256:f1886e6c… (matches Dockerfile) |
# | container-structure-test  | container-structure-test | ghcr.io/googlecontainertools/...:1.22.1@sha256:710da3ca… (matches Dockerfile) |
#
# Usage:
#   bash scripts/check-container-local.sh --dockerfile Dockerfile --context .
# Optional: --image NAME (skip build), --structure-test path, --skip-scan,
#           --advisory (do not fail on trivy findings; default is blocking),
#           --no-ignorefile (skip ignorefile fallback; mirrors
#           container-scan.yml ignorefile=none),
#           --skip-age (skip DOCKER-BUILD-006 base-image age gate)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

DOCKERFILE="Dockerfile"
CONTEXT="."
IMAGE=""
STRUCTURE_TEST=""
SKIP_SCAN=0
SKIP_AGE=0
ADVISORY=0
NO_IGNOREFILE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dockerfile) DOCKERFILE="$2"; shift 2 ;;
    --context) CONTEXT="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    --structure-test) STRUCTURE_TEST="$2"; shift 2 ;;
    --skip-scan) SKIP_SCAN=1; shift ;;
    --skip-age) SKIP_AGE=1; shift ;;
    --advisory) ADVISORY=1; shift ;;
    --no-ignorefile) NO_IGNOREFILE=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "error: Dockerfile not found: ${DOCKERFILE}" >&2
  exit 2
fi
if [[ ! -d "${CONTEXT}" ]]; then
  echo "error: context directory not found: ${CONTEXT}" >&2
  exit 2
fi

THRESHOLDS="${ROOT}/scripts/docker.profile.thresholds.yml"
if [[ ! -f "${THRESHOLDS}" ]]; then
  THRESHOLDS="${ROOT}/docs/guardrails/docker/profile.thresholds.yml"
fi
if [[ ! -f "${THRESHOLDS}" ]]; then
  echo "Missing ${THRESHOLDS}; init the guardrails submodule first." >&2
  exit 1
fi

MAX_MB="$(bash "${ROOT}/scripts/read-thresholds.sh" image_max_size_mb "${THRESHOLDS}")"
MIN_EFF="$(bash "${ROOT}/scripts/read-thresholds.sh" min_image_efficiency_percent "${THRESHOLDS}")"
HADOLINT_LEVEL="$(bash "${ROOT}/scripts/read-thresholds.sh" hadolint_failure_threshold "${THRESHOLDS}")"
MAX_AGE="$(bash "${ROOT}/scripts/read-thresholds.sh" base_image_max_age_days "${THRESHOLDS}")"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

echo "==> hadolint (${HADOLINT_LEVEL})"
if command -v hadolint >/dev/null 2>&1; then
  hadolint --failure-threshold "${HADOLINT_LEVEL}" "${DOCKERFILE}"
else
  docker run --rm -i hadolint/hadolint:2.12.0-alpine@sha256:3c206a451cec6d486367e758645269fd7d696c5ccb6ff59d8b03b0e45268a199 \
    hadolint --failure-threshold "${HADOLINT_LEVEL}" - < "${DOCKERFILE}"
fi

if (( SKIP_AGE == 0 )); then
  echo "==> base image age (max ${MAX_AGE} days)"
  bash "${ROOT}/scripts/check-base-image-age.sh" "${DOCKERFILE}" "${MAX_AGE}"
fi

if [[ -z "${IMAGE}" ]]; then
  IMAGE="containerdevops-local:$(date +%s)"
  echo "==> buildx build → ${IMAGE}"
  docker buildx build --load -t "${IMAGE}" -f "${DOCKERFILE}" "${CONTEXT}"
fi

if [[ -n "${STRUCTURE_TEST}" ]]; then
  if [[ ! -f "${STRUCTURE_TEST}" ]]; then
    echo "error: structure-test config not found: ${STRUCTURE_TEST}" >&2
    exit 2
  fi
  echo "==> container-structure-test"
  if command -v container-structure-test >/dev/null 2>&1; then
    container-structure-test test --image "${IMAGE}" --config "${STRUCTURE_TEST}"
  else
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
      -v "${PWD}:/work:ro" -w /work \
      ghcr.io/googlecontainertools/container-structure-test:1.22.1@sha256:710da3ca8ed29a42423315592f74f02df4e3d2ba19f1df7257bd481ea75ba5aa \
      test --image "${IMAGE}" --config "${STRUCTURE_TEST}"
  fi
fi

echo "==> image size"
bash "${ROOT}/scripts/check-image-size.sh" "${IMAGE}" "${MAX_MB}"

echo "==> dive efficiency (min ${MIN_EFF}%)"
DIVE_DIR="$(mktemp -d)"
DIVE_JSON="${DIVE_DIR}/dive.json"
trap 'rm -rf "${DIVE_DIR}"' EXIT
set +e
if command -v dive >/dev/null 2>&1; then
  dive --ci --json "${DIVE_JSON}" "${IMAGE}"
  dive_rc=$?
else
  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${DIVE_DIR}:/out" \
    wagoodman/dive:v0.13.1@sha256:f1886e6c32c094fc41a623c1989f5cb3e48aa766da5f0be233f911fc1d85ce10 \
    --ci --json /out/dive.json "${IMAGE}"
  dive_rc=$?
fi
set -e
if [[ ! -f "${DIVE_JSON}" || ! -s "${DIVE_JSON}" ]]; then
  echo "dive failed without JSON (exit ${dive_rc}) — not an efficiency miss" >&2
  if (( ADVISORY == 0 )); then
    exit "${dive_rc}"
  fi
else
  bash "${ROOT}/scripts/check-image-efficiency.sh" "${MIN_EFF}" "${DIVE_JSON}"
fi

if (( SKIP_SCAN == 0 )); then
  echo "==> trivy image"
  IGNORE=()
  if (( NO_IGNOREFILE == 1 )); then
    echo "  --no-ignorefile: skipping Trivy ignorefiles"
  elif [[ -f "${CONTEXT}/.trivyignore.yaml" ]]; then
    IGNORE=(--ignorefile "${CONTEXT}/.trivyignore.yaml")
  elif [[ -f .trivyignore.yaml ]]; then
    IGNORE=(--ignorefile .trivyignore.yaml)
  elif [[ -f .trivyignore ]]; then
    IGNORE=(--ignorefile .trivyignore)
  fi
  set +e
  if command -v trivy >/dev/null 2>&1; then
    trivy image --severity HIGH,CRITICAL --pkg-types library --exit-code 1 "${IGNORE[@]}" "${IMAGE}"
  else
    # Resolve ignorefile paths inside the container mount at /work
    DIGNORE=()
    if [[ ${#IGNORE[@]} -gt 0 ]]; then
      ig="${IGNORE[1]}"
      if [[ "${ig}" == /* ]]; then
        rel="${ig#"${PWD}"/}"
        DIGNORE=(--ignorefile "/work/${rel}")
      else
        DIGNORE=(--ignorefile "/work/${ig}")
      fi
    fi
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
      -v "${PWD}:/work:ro" -w /work \
      aquasec/trivy:0.73.0@sha256:7cced7cae583819fc7806d4cbc0dbbc7cad18b99f7d3e235192e6da8c091045c image --severity HIGH,CRITICAL --pkg-types library --exit-code 1 \
      "${DIGNORE[@]}" "${IMAGE}"
  fi
  trc=$?
  set -e
  if (( trc != 0 )); then
    if (( ADVISORY == 1 )); then
      echo "trivy findings (advisory — continuing)"
    else
      echo "trivy findings (blocking). Pass --advisory to continue." >&2
      exit "${trc}"
    fi
  fi
fi

echo "Local container checks finished for ${IMAGE}."
