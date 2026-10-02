#!/usr/bin/env bash
# Shared image scan used by container-scan and the in-job scan on container-build.
# DOCKER-SEC-001 (vuln) and DOCKER-SEC-005 (vuln,secret by default).
#
# Usage: scan-image.sh trivy|syft|grype
#   IMAGE        required image ref (local tag or registry digest)
#   PKG_TYPES    trivy --pkg-types (default os,library)
#   IGNOREFILE   path, empty (auto .trivyignore.yaml), or none
#   SEV          fail threshold (trivy wants upper case, grype lower)
#   SCANNERS     trivy --scanners (default vuln,secret)
#   IMAGE_CONFIG_SCANNERS  trivy --image-config-scanners (default misconfig,secret; empty disables)
#   RESULTS_DIR  default scan-results
set -euo pipefail

cmd="${1:?subcommand required: trivy|syft|grype}"
IMAGE="${IMAGE:?IMAGE is required}"
PKG_TYPES="${PKG_TYPES:-os,library}"
IGNOREFILE="${IGNOREFILE:-}"
SCANNERS="${SCANNERS:-vuln,secret}"
# ${var-default} so an explicit empty value disables the config scan.
IMAGE_CONFIG_SCANNERS="${IMAGE_CONFIG_SCANNERS-misconfig,secret}"
RESULTS_DIR="${RESULTS_DIR:-scan-results}"
mkdir -p "${RESULTS_DIR}"

case "${cmd}" in
  trivy)
    SEV="${SEV:?SEV is required}"
    CFG=()
    [[ -f trivy.yaml ]] && CFG=(--config trivy.yaml)
    IGNORE=()
    if [[ "${IGNOREFILE}" == "none" ]]; then
      echo "ignorefile=none — skipping Trivy ignorefiles"
    elif [[ -n "${IGNOREFILE}" && -f "${IGNOREFILE}" ]]; then
      IGNORE=(--ignorefile "${IGNOREFILE}")
    elif [[ -n "${IGNOREFILE}" ]]; then
      echo "error: ignorefile path not found: ${IGNOREFILE}" >&2
      exit 1
    elif [[ -f .trivyignore.yaml ]]; then
      IGNORE=(--ignorefile .trivyignore.yaml)
    elif [[ -f .trivyignore ]]; then
      IGNORE=(--ignorefile .trivyignore)
    fi
    CONFIG_SCAN=()
    if [[ -n "${IMAGE_CONFIG_SCANNERS}" ]]; then
      CONFIG_SCAN=(--image-config-scanners "${IMAGE_CONFIG_SCANNERS}")
    fi
    trivy image --scanners "${SCANNERS}" --pkg-types "${PKG_TYPES}" \
      --severity "CRITICAL,${SEV}" \
      --format sarif --output "${RESULTS_DIR}/trivy.sarif" \
      "${CFG[@]}" "${CONFIG_SCAN[@]}" "${IGNORE[@]}" "${IMAGE}"
    trivy image --scanners "${SCANNERS}" --pkg-types "${PKG_TYPES}" \
      --severity "CRITICAL,${SEV}" \
      --exit-code 1 "${CFG[@]}" "${CONFIG_SCAN[@]}" "${IGNORE[@]}" "${IMAGE}"
    ;;
  syft)
    SELECT=()
    if [[ "${PKG_TYPES}" == "library" ]]; then
      # Language catalogs, not python-only. Omit golang/binary so Grype
      # does not fail on vendor-static Go donors already in .trivyignore.yaml.
      SELECT=(--select-catalogers "python,javascript,java,dotnet,ruby,php,rust,dart,swift")
    fi
    syft "${IMAGE}" "${SELECT[@]}" \
      -o "cyclonedx-json=${RESULTS_DIR}/sbom.cdx.json" \
      -o "spdx-json=${RESULTS_DIR}/sbom.spdx.json"
    ;;
  grype)
    SEV="${SEV:?SEV is required}"
    CFG=()
    [[ -f .grype.yaml ]] && CFG=(--config .grype.yaml)
    if [[ -f "${RESULTS_DIR}/sbom.cdx.json" ]]; then
      grype "sbom:${RESULTS_DIR}/sbom.cdx.json" "${CFG[@]}" --fail-on "${SEV}" \
        -o "json=${RESULTS_DIR}/grype.json"
    else
      grype "${IMAGE}" "${CFG[@]}" --fail-on "${SEV}" \
        -o "json=${RESULTS_DIR}/grype.json"
    fi
    ;;
  *)
    echo "error: unknown subcommand '${cmd}' (trivy|syft|grype)" >&2
    exit 2
    ;;
esac
