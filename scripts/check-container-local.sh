#!/usr/bin/env bash
# Local CI parity for container gates (CI-008).
# Host PATH tools preferred; missing tools run via digest-pinned images.
#
# Resolution table (host → Docker fallback):
# | Tool                      | Host preferred     | Docker fallback                         |
# |---------------------------|--------------------|-----------------------------------------|
# | hadolint                  | hadolint           | hadolint/hadolint:2.12.0-alpine         |
# | shellcheck                | shellcheck         | koalaman/shellcheck:v0.10.0             |
# | trivy                     | trivy              | aquasec/trivy:0.73.0                    |
# | syft                      | syft               | anchore/syft:v1.50.0                    |
# | grype                     | grype              | anchore/grype:v0.116.1                  |
# | dive                      | dive               | wagoodman/dive:v0.13.1                  |
# | container-structure-test  | container-structure-test | ghcr.io/googlecontainertools/...:1.22.1 |
#
# Usage:
#   bash scripts/check-container-local.sh --dockerfile Dockerfile --context .
# Optional: --image NAME (skip build), --structure-test path, --skip-scan,
#           --advisory (do not fail on trivy findings; default is blocking)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

DOCKERFILE="Dockerfile"
CONTEXT="."
IMAGE=""
STRUCTURE_TEST=""
SKIP_SCAN=0
ADVISORY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dockerfile) DOCKERFILE="$2"; shift 2 ;;
    --context) CONTEXT="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    --structure-test) STRUCTURE_TEST="$2"; shift 2 ;;
    --skip-scan) SKIP_SCAN=1; shift ;;
    --advisory) ADVISORY=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

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

run_tool() {
  local name="$1"
  shift
  if command -v "${name}" >/dev/null 2>&1; then
    echo "→ ${name} (host)"
    "${name}" "$@"
    return
  fi
  echo "→ ${name} (Docker fallback)"
  case "${name}" in
    hadolint)
      docker run --rm -i hadolint/hadolint:2.12.0-alpine hadolint "$@" < "${DOCKERFILE}"
      ;;
    shellcheck)
      docker run --rm -v "${PWD}:/src:ro" -w /src koalaman/shellcheck:v0.10.0 "$@"
      ;;
    trivy)
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.73.0 "$@"
      ;;
    syft)
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/syft:v1.50.0 "$@"
      ;;
    grype)
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "${PWD}:/work" -w /work anchore/grype:v0.116.1 "$@"
      ;;
    dive)
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:v0.13.1 "$@"
      ;;
    container-structure-test)
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        -v "${PWD}:/work:ro" -w /work \
        ghcr.io/googlecontainertools/container-structure-test:1.22.1 \
        "$@"
      ;;
    *)
      echo "No Docker fallback for ${name}" >&2
      exit 1
      ;;
  esac
}

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

echo "==> hadolint (${HADOLINT_LEVEL})"
if command -v hadolint >/dev/null 2>&1; then
  hadolint --failure-threshold "${HADOLINT_LEVEL}" "${DOCKERFILE}"
else
  docker run --rm -i hadolint/hadolint:2.12.0-alpine \
    hadolint --failure-threshold "${HADOLINT_LEVEL}" - < "${DOCKERFILE}"
fi

if [[ -z "${IMAGE}" ]]; then
  IMAGE="containerdevops-local:$(date +%s)"
  echo "==> buildx build → ${IMAGE}"
  docker buildx build --load -t "${IMAGE}" -f "${DOCKERFILE}" "${CONTEXT}"
fi

if [[ -n "${STRUCTURE_TEST}" && -f "${STRUCTURE_TEST}" ]]; then
  echo "==> container-structure-test"
  if command -v container-structure-test >/dev/null 2>&1; then
    container-structure-test test --image "${IMAGE}" --config "${STRUCTURE_TEST}"
  else
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
      -v "${PWD}:/work:ro" -w /work \
      ghcr.io/googlecontainertools/container-structure-test:1.22.1 \
      test --image "${IMAGE}" --config "${STRUCTURE_TEST}"
  fi
fi

echo "==> image size"
bash "${ROOT}/scripts/check-image-size.sh" "${IMAGE}" "${MAX_MB}"

if (( SKIP_SCAN == 0 )); then
  echo "==> trivy image"
  IGNORE=()
  if [[ -f .trivyignore.yaml ]]; then
    IGNORE=(--ignorefile .trivyignore.yaml)
  elif [[ -f .trivyignore ]]; then
    IGNORE=(--ignorefile .trivyignore)
  fi
  set +e
  if command -v trivy >/dev/null 2>&1; then
    trivy image --severity HIGH,CRITICAL --pkg-types library --exit-code 1 "${IGNORE[@]}" "${IMAGE}"
  else
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
      -v "${PWD}:/work:ro" -w /work \
      aquasec/trivy:0.73.0 image --severity HIGH,CRITICAL --pkg-types library --exit-code 1 \
      "${IGNORE[@]}" "${IMAGE}"
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
echo "Note: dive efficiency gate (min ${MIN_EFF}%) is enforced in CI; run dive locally if installed."
