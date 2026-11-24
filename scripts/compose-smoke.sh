#!/usr/bin/env bash
# Boot a Compose project and tear it down (CDO-SMOKE-001, DOCKER-LINT-003).
#
# Env:
#   COMPOSE_FILES      space-separated compose files
#   COMPOSE_ENV_FILES  space-separated env files passed to --env-file
#   COMPOSE_STACKS     optional. Each non-empty line is compose_file or
#                      compose_file|env_file. Stacks come up one after another.
#   COMPOSE_PROJECT    project name (default: compose-smoke)
# Requires: docker. COMPOSE_FILES or COMPOSE_STACKS is required.
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
	echo "error: docker is required" >&2
	exit 1
fi

if [[ -z "${COMPOSE_FILES:-}" && -z "${COMPOSE_STACKS:-}" ]]; then
	echo "error: COMPOSE_FILES or COMPOSE_STACKS is required" >&2
	exit 2
fi

smoke_one() {
	local project="$1"
	shift
	local -a env_args=()
	local -a file_args=()
	local compose_file env_file
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--env-file)
			env_file="$2"
			if [[ ! -f "${env_file}" ]]; then
				echo "error: env file not found: ${env_file}" >&2
				exit 2
			fi
			env_args+=(--env-file "${env_file}")
			shift 2
			;;
		*)
			compose_file="$1"
			if [[ ! -f "${compose_file}" ]]; then
				echo "error: compose file not found: ${compose_file}" >&2
				exit 2
			fi
			file_args+=(-f "${compose_file}")
			shift
			;;
		esac
	done

	# Expand now. A later EXIT trap must not read locals that have gone.
	local down_cmd
	printf -v down_cmd 'docker compose --project-name %q' "${project}"
	local arg
	for arg in "${env_args[@]}" "${file_args[@]}"; do
		printf -v down_cmd '%s %q' "${down_cmd}" "${arg}"
	done
	down_cmd+=" down --remove-orphans --timeout 20 || true"
	# shellcheck disable=SC2064
	trap "${down_cmd}" EXIT

	echo "Smoke up --wait project=${project}"
	docker compose --project-name "${project}" "${env_args[@]}" "${file_args[@]}" up --wait
	eval "${down_cmd}"
	trap - EXIT
	echo "Smoke up succeeded project=${project}"
}

base="${COMPOSE_PROJECT:-compose-smoke}"

if [[ -n "${COMPOSE_STACKS:-}" ]]; then
	index=0
	while IFS= read -r line || [[ -n "${line}" ]]; do
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"
		[[ -z "${line}" || "${line}" == \#* ]] && continue
		index=$((index + 1))
		compose_file="${line%%|*}"
		if [[ "${line}" == *"|"* ]]; then
			env_file="${line#*|}"
			smoke_one "${base}-${index}" --env-file "${env_file}" "${compose_file}"
		else
			smoke_one "${base}-${index}" "${compose_file}"
		fi
	done <<<"${COMPOSE_STACKS}"
	if [[ "${index}" -eq 0 ]]; then
		echo "error: COMPOSE_STACKS has no stacks" >&2
		exit 2
	fi
	exit 0
fi

args=()
# shellcheck disable=SC2086
for env_file in ${COMPOSE_ENV_FILES:-}; do
	args+=(--env-file "${env_file}")
done
# shellcheck disable=SC2086
for compose_file in ${COMPOSE_FILES}; do
	args+=("${compose_file}")
done
smoke_one "${base}" "${args[@]}"
