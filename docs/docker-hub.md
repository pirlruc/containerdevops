# ci-container

Short-lived CI toolchain image for container jobs. Extends `ci-lint` with dive
and container-structure-test. Not a product runtime — no `HEALTHCHECK`.

## Image

| Item | Value |
|------|--------|
| Docker Hub | `pirlruc/ci-container` |
| Architectures | `linux/amd64` |
| User | non-root `1000:1000` |
| Base | `pirlruc/ci-lint` (digest-pinned at publish) |

### Tags

| Tag | Meaning |
|-----|---------|
| `6.0.2` / `6.0.2-alpine` | Alpine `sha256:8acbde10296d715f02174d0825689276fbcb46186c888ecb4ede82b2110a8f1a` |
| `6.0.2-debian` | Debian `sha256:6e0df10282985ac503cee69f869f1784789735713c9c5e5f2d52070280792cd4` |
| `6.0.0` / `6.0.0-alpine` | Previous Alpine `sha256:10f60eae5efd277c78f8f9c7e27e5376e8f4b1ed299eae7756a5c332c0b48f05` |
| `6.0.0-debian` | Previous Debian `sha256:80ee93aa0a702374c6072d637f4ae46b0f1302ca5da610b62dc5f1511133025e` |
| `5.0.3` / `5.0.3-alpine` | Previous Alpine `sha256:3aeed6541a875ff4b4c0954cb838a1414800c0f3231970acbb7e2bbef9783d00` |
| `5.0.3-debian` | Immutable Debian `sha256:14f26db2831086123bf79caa3aac39e337edcc565d41ea894a376f463d850ef7` |
| `5.0.0` / `5.0.0-alpine` | Previous Alpine `sha256:0d4328a0b6051a87df5baa70b19edeaa521ee479462268fe7b2be619209a42d4` |
| `5.0.0-debian` | Previous Debian `sha256:a4d6a2dd0c9ea1d6e09c78962e7fc918e42607e3461489bf17c1118308582c86` |
| `latest` / `latest-alpine` | Latest non-prerelease Alpine publish |
| `latest-debian` | Latest non-prerelease Debian publish |
| `sha-<git>` / `sha-<git>-alpine` / `sha-<git>-debian` | Exact git SHA of the published commit |

Alpine owns the unsuffixed tags to match `ci-lint` (lower OS vulnerability
posture). Prefer an explicit `-alpine` / `-debian` suffix when the libc matters;
prefer a digest in production.
`latest` equals `latest-alpine` (`flavor: latest=false`). A monthly rebuild may
move `latest` off the SemVer tag — pin the digest, not `latest`.

```bash
docker pull pirlruc/ci-container:5.0.3
# or
docker pull pirlruc/ci-container:5.0.3-debian
docker pull pirlruc/ci-container@sha256:3aeed6541a875ff4b4c0954cb838a1414800c0f3231970acbb7e2bbef9783d00
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-container:5.0.3 \
  hadolint Dockerfile
```

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  pirlruc/ci-container:5.0.3 \
  dive --ci my-app:local
```

Hardened local run (read-only workspace mount):

```bash
docker run --rm \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --tmpfs /tmp:rw,noexec,nosuid,size=256m \
  -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-container:5.0.3 \
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
# Prefer digest pins
docker pull pirlruc/ci-container@sha256:3aeed6541a875ff4b4c0954cb838a1414800c0f3231970acbb7e2bbef9783d00

# Cosign keyless verify (when the image was signed on a public repo)
cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/containerdevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  pirlruc/ci-container@sha256:3aeed6541a875ff4b4c0954cb838a1414800c0f3231970acbb7e2bbef9783d00
```

## Vulnerabilities

Donor Go binaries (dive, structure-test, actionlint) embed dependency CVEs that
only clear when upstream publishes a newer digest. The publish gate uses
`--pkg-types library`.

## License

MIT
