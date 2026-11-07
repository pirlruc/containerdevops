#!/bin/sh
# Append an index and platform digest table to the GitHub Release for TAG.
# REL-PUB-005. Image refs are arguments. A missing ref fails the script.
set -eu

if [ -z "${TAG:-}" ] || [ -z "${REPO:-}" ]; then
	echo "TAG and REPO are required" >&2
	exit 1
fi
if [ "$#" -eq 0 ]; then
	echo "pass at least one image ref" >&2
	exit 1
fi

{
	printf '%s\n' "## Image digests"
	printf '\n'
	printf '%s\n' "| Image | Index | Platform |"
	printf '%s\n' "| --- | --- | --- |"
	for ref in "$@"; do
		index=$(docker buildx imagetools inspect --format '{{json .Manifest.Digest}}' "${ref}" | tr -d '"')
		docker buildx imagetools inspect --format '{{range .Manifest.Manifests}}{{.Platform.OS}}/{{.Platform.Architecture}} {{.Digest}}{{println}}{{end}}' "${ref}" |
			awk -v ref="${ref}" -v index="${index}" 'NF { printf "| `%s` | `%s` | %s `%s` |\n", ref, index, $1, $2 }'
	done
} >release-digests.md

body=$(gh release view "${TAG}" --repo "${REPO}" --json body --jq .body)
printf '%s\n\n' "${body}" >release-body.md
cat release-digests.md >>release-body.md
gh release edit "${TAG}" --repo "${REPO}" --notes-file release-body.md
echo "updated ${TAG}"
