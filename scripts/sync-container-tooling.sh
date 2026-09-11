#!/usr/bin/env bash
# Seed container tooling templates into a consuming repo (create-once).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CDO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET="${1:?usage: sync-container-tooling.sh /path/to/repo}"
TARGET="$(cd "${TARGET}" && pwd)"
REF="${CONTAINERDEVOPS_REF:-$(git -C "${CDO_ROOT}" rev-parse HEAD 2>/dev/null || echo main)}"

mkdir -p "${TARGET}/.github/workflows" "${TARGET}/docs"

seed_once() {
  local src="$1" dest="$2"
  if [[ -e "${dest}" ]]; then
    echo "Kept existing ${dest}"
  else
    cp "${src}" "${dest}"
    echo "Seeded ${dest}"
  fi
}

for f in .hadolint.yaml trivy.yaml .trivyignore .grype.yaml .syft.yaml \
         container-structure-test.yml .dive-ci kics.config dockerignore.template; do
  if [[ -f "${CDO_ROOT}/templates/${f}" ]]; then
    dest_name="${f}"
    [[ "${f}" == "dockerignore.template" ]] && dest_name=".dockerignore"
    seed_once "${CDO_ROOT}/templates/${f}" "${TARGET}/${dest_name}"
  fi
done

CALLER="${TARGET}/.github/workflows/ci-container.yml"
if [[ -e "${CALLER}" ]]; then
  echo "Kept existing ${CALLER}"
else
  # Replace every PLACEHOLDER_SHA token (uses: @PLACEHOLDER_SHA and bare
  # scripts_ref: PLACEHOLDER_SHA) so seeded callers keep uses:/scripts_ref lockstep.
  sed "s|PLACEHOLDER_SHA|${REF}|g" \
    "${CDO_ROOT}/templates/ci-container.yml" > "${CALLER}"
  echo "Seeded ${CALLER} (pinned @${REF})"
fi

echo "Container tooling sync complete for ${TARGET}"
