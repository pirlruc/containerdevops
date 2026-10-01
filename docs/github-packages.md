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
| `6.0.7` / `6.0.7-alpine` | Alpine `sha256:9cecca568d67dfe3debad6431153accf7fb466e08f2b97f08950b3018affe1d9` |
| `6.0.7-debian` | Debian `sha256:dc0c7444fa56183064e8de599fa9ac94affca67c77aa403720192d232548ac0f` |
| `6.0.5` / `6.0.5-alpine` | Previous Alpine `sha256:09b97b6c4dfdde9f43113c1000bbae2f80aaae194725ffe1e8f1ccc8ff3204e0` |
| `6.0.5-debian` | Previous Debian `sha256:38fb1ced38c9e128036a4dfdbf719ca633d6a926384f7f1d78b8d13eb628afed` |
| `6.0.2` / `6.0.2-alpine` | Previous Alpine `sha256:8acbde10296d715f02174d0825689276fbcb46186c888ecb4ede82b2110a8f1a` |
| `6.0.2-debian` | Previous Debian `sha256:6e0df10282985ac503cee69f869f1784789735713c9c5e5f2d52070280792cd4` |
| `6.0.0` / `6.0.0-alpine` | Previous Alpine `sha256:10f60eae5efd277c78f8f9c7e27e5376e8f4b1ed299eae7756a5c332c0b48f05` |
| `6.0.0-debian` | Previous Debian `sha256:80ee93aa0a702374c6072d637f4ae46b0f1302ca5da610b62dc5f1511133025e` |
| `5.0.3` / `5.0.3-alpine` | Previous Alpine `sha256:3aeed6541a875ff4b4c0954cb838a1414800c0f3231970acbb7e2bbef9783d00` |
| `5.0.3-debian` | Immutable Debian `sha256:14f26db2831086123bf79caa3aac39e337edcc565d41ea894a376f463d850ef7` |
| `5.0.0` / `5.0.0-alpine` | Previous Alpine `sha256:0d4328a0b6051a87df5baa70b19edeaa521ee479462268fe7b2be619209a42d4` |
| `5.0.0-debian` | Previous Debian `sha256:a4d6a2dd0c9ea1d6e09c78962e7fc918e42607e3461489bf17c1118308582c86` |
| `latest` / `latest-alpine` | Latest non-prerelease Alpine publish |
| `latest-debian` | Latest non-prerelease Debian publish |
| `sha-<git>` / `sha-<git>-alpine` / `sha-<git>-debian` | Exact git SHA of the published commit |

Alpine owns the unsuffixed tags to match `ci-lint`. Prefer an explicit
`-alpine` / `-debian` suffix when the libc matters; prefer a digest in production.
`latest` equals `latest-alpine` (`flavor: latest=false`). A monthly rebuild may
move `latest` off the SemVer tag — pin the digest, not `latest`.

## Authentication

If the package is public, anonymous pulls work:

```bash
docker pull ghcr.io/pirlruc/ci-container:6.0.7
```

If the package is private, authenticate with a PAT that has `read:packages`:

```bash
echo "$CR_PAT" | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/pirlruc/ci-container:6.0.7
# or
docker pull ghcr.io/pirlruc/ci-container@sha256:9cecca568d67dfe3debad6431153accf7fb466e08f2b97f08950b3018affe1d9
```

## Use as a GitHub Actions job container

```yaml
jobs:
  lint:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/pirlruc/ci-container:6.0.7
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
  ghcr.io/pirlruc/ci-container:6.0.7 \
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
  ghcr.io/pirlruc/ci-container:6.0.7 \
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
docker pull ghcr.io/pirlruc/ci-container@sha256:9cecca568d67dfe3debad6431153accf7fb466e08f2b97f08950b3018affe1d9

cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/containerdevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/pirlruc/ci-container@sha256:9cecca568d67dfe3debad6431153accf7fb466e08f2b97f08950b3018affe1d9
```

Signing runs only when the source repository is public (`sign: true`).

## Vulnerabilities

Donor Go binaries (dive, structure-test, actionlint) embed dependency CVEs that
only clear when upstream publishes a newer digest. The publish gate uses
`--pkg-types library`.

## License

MIT
