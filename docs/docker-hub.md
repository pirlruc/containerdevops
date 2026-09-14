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
| `5.0.0` / `5.0.0-alpine` | Immutable Alpine release (default unsuffixed = Alpine) |
| `5.0.0-debian` | Immutable Debian 13 release |
| `latest` / `latest-alpine` | Latest non-prerelease Alpine publish |
| `latest-debian` | Latest non-prerelease Debian publish |
| `sha-<git>` / `sha-<git>-alpine` / `sha-<git>-debian` | Exact git SHA of the published commit |

Alpine owns the unsuffixed tags to match `ci-lint` (lower OS vulnerability
posture). Prefer an explicit `-alpine` / `-debian` suffix when the libc matters;
prefer a digest in production.

```bash
docker pull pirlruc/ci-container:5.0.0
# or
docker pull pirlruc/ci-container:5.0.0-debian
# or
docker pull pirlruc/ci-container@sha256:<digest>
```

## Quick start

```bash
docker run --rm -v "$PWD:/workspace:ro" -w /workspace \
  pirlruc/ci-container:5.0.0 \
  hadolint Dockerfile
```

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  pirlruc/ci-container:5.0.0 \
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
  pirlruc/ci-container:5.0.0 \
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
docker pull pirlruc/ci-container@sha256:<digest>

# Cosign keyless verify (when the image was signed on a public repo)
cosign verify \
  --certificate-identity-regexp 'https://github.com/pirlruc/containerdevops/.github/workflows/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  pirlruc/ci-container@sha256:<digest>
```

## Vulnerabilities

Donor Go binaries (dive, structure-test, actionlint) embed dependency CVEs that
only clear when upstream publishes a newer digest. The publish gate uses
`--pkg-types library`.

## License

MIT
