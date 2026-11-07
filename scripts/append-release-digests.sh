#!/bin/sh
# Append an index and platform digest table to the GitHub Release for TAG.
# REL-PUB-005. Image refs are arguments. A missing ref fails the script.
# A second run replaces an existing "## Image digests" section.
set -eu

if [ -z "${TAG:-}" ] || [ -z "${REPO:-}" ]; then
	echo "TAG and REPO are required" >&2
	exit 1
fi
if [ "$#" -eq 0 ]; then
	echo "pass at least one image ref" >&2
	exit 1
fi

# imagetools without a login asks GHCR anonymously. Private packages return 401.
# The job token has packages: read. gawk rejects -v index= (index is a builtin).
if [ -n "${GH_TOKEN:-}" ]; then
	printf '%s' "${GH_TOKEN}" | docker login ghcr.io -u "${GHCR_USER:-github-actions[bot]}" --password-stdin
fi

{
	printf '%s\n' "## Image digests"
	printf '\n'
	printf '%s\n' "| Image | Index | Platform |"
	printf '%s\n' "| --- | --- | --- |"
	for ref in "$@"; do
		raw=$(docker buildx imagetools inspect --format '{{json .Manifest.Digest}}' "${ref}") || exit 1
		index_digest=$(printf '%s' "${raw}" | tr -d '"')
		if [ -z "${index_digest}" ]; then
			echo "missing index digest for ${ref}" >&2
			exit 1
		fi
		platforms=$(docker buildx imagetools inspect --format '{{range .Manifest.Manifests}}{{.Platform.OS}}/{{.Platform.Architecture}} {{.Digest}}{{println}}{{end}}' "${ref}") || exit 1
		if [ -z "${platforms}" ]; then
			echo "no platform manifests for ${ref}" >&2
			exit 1
		fi
		printf '%s\n' "${platforms}" | awk -v ref="${ref}" -v index_digest="${index_digest}" 'NF { printf "| `%s` | `%s` | %s `%s` |\n", ref, index_digest, $1, $2 }'
	done
} >release-digests.md

body=$(gh release view "${TAG}" --repo "${REPO}" --json body --jq '.body // ""')
printf '%s\n' "${body}" | awk '
	/^## Image digests$/ { skip = 1; next }
	skip && /^## / { skip = 0 }
	!skip { print }
' >release-body.md
printf '\n' >>release-body.md
cat release-digests.md >>release-body.md
gh release edit "${TAG}" --repo "${REPO}" --notes-file release-body.md
echo "updated ${TAG}"
