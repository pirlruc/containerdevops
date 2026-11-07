---
name: container-implementations
description: 'Dockerfile and Compose authoring conventions for this repo and its templates. Use when editing files that match: **/Dockerfile*,**/templates/**,.github/workflows/container-*.yml.'
paths: '**/Dockerfile*,**/templates/**,.github/workflows/container-*.yml'
disable-model-invocation: true
---

<!-- Generated from .cursor/rules by scripts/render-agent-instructions.py. Edit the .mdc files, then re-run that script. -->

Cursor applies the matching `.cursor/rules` file by glob and does not auto-invoke this skill. Other agents should follow this skill when the description matches.

# containerdevops implementations

When editing reusable workflows, scripts, or `templates/` for consumers:

1. Keep the `blocking` / `ADVISORY` contract identical to cppdevops
   (`continue-on-error: ${{ env.ADVISORY == 'true' }}`).
2. Prefer curl/apt install of pinned tool versions in CI over unpinned marketplace
   actions for scanners (mirror cppdevops). Pin `actions/checkout` by SHA.
3. Read numeric floors from the pinned `docs/guardrails/docker/profile.thresholds.yml`
   via `scripts/read-thresholds.sh` — never hardcode org floors in workflows.
4. Product-image guidance for consumers is in scaffold
   [`container-images.mdc`](https://github.com/pirlruc/github-scaffold/blob/main/.cursor/rules/container-images.mdc);
   cite `DOCKER-*` IDs in PR and Epic text.
5. Local parity (`scripts/check-container-local.sh`) must keep a host-vs-Docker
   resolution table; missing host tools run from digest-pinned images without
   system installs ([build-test-environments](https://github.com/pirlruc/github-scaffold/blob/main/.cursor/rules/build-test-environments.mdc)).
