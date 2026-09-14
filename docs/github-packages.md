# ci-container (GitHub Packages)

Short-lived CI toolchain image for container jobs. Extends `ci-lint` with dive
and container-structure-test. Not a product runtime — no `HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| GHCR | `ghcr.io/pirlruc/ci-container` |
| Architectures | `linux/amd64` |
| User | non-root `1000:1000` |
| Base | `ghcr.io/pirlruc/ci-lint` (digest-pinned at publish) |

### Tags

| Tag | Meaning |
|-----|---------|
| `5.0.0` / `5.0.0-alpine` | Immutable Alpine release (default unsuffixed = Alpine) |
| `5.0.0-debian` | Immutable Debian 13 release |
| `latest` / `latest-alpine` | Latest non-prerelease Alpine publish |
| `latest-debian` | Latest non-prerelease Debian publish |
| `sha-<git>` / `sha-<git>-alpine` / `sha-<git>-debian` | Exact git SHA of the published commit |

Alpine owns the unsuffixed tags to match `ci-lint`. Prefer an explicit
`-alpine` / `-debian` suffix when the libc matters; prefer a digest in production.

## Authentication

If the package is public, anonymous pulls work:

```bash
docker pull ghcr.io/pirlruc/ci-container:5.0.0
```

If the package is private, authenticate with a PAT that has `read:packages`:

```bash
echo "$CR_PAT" | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/pirlruc/ci-container:5.0.0
# or
docker pull ghcr.io/pirlruc/ci-container@sha256:<digest>
```

## Use as a GitHub Actions job container

```yaml
jobs:
  lint:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/pirlruc/ci-container:5.0.0
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - run: hadolint Dockerfile
```

Grant the package **Actions** Read access for the calling repository when using
`GITHUB_TOKEN`, or pass a PAT with `read:packages`.

## Quick start (local)

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  ghcr.io/pirlruc/ci-container:5.0.0 \
  hadolint Dockerfile
```

Hardened local run:

```bash
docker run --rm \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --tmpfs /tmp:rw,noexec,nosuid,size=256m \
  -v "$PWD:/workspace:ro" -w /workspace \
  ghcr.io/pirlruc/ci-container:5.0.0 \
  hadolint Dockerfile
```

## What is inside

Everything in `ci-lint`, plus:

| Tool | Role |
|------|------|
| dive | Image layer efficiency |
| container-structure-test | Image structure / command tests |

Not included: syft, grype, trivy, grant, cosign (use `ci-supply-chain` or the
plain runner).

## Verify a publish

```bash
docker pull ghcr.io/pirlruc/ci-container@sha256:<digest>

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/containerdevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/pirlruc/ci-container@sha256:<digest>
```

Signing runs only when the source repository is public (`sign: true`).

## Vulnerabilities

Donor Go binaries (dive, structure-test, actionlint) embed dependency CVEs that
only clear when upstream publishes a newer digest. The publish gate uses
`--pkg-types library`.

## License

MIT
