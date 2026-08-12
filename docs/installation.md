# Installation guide

## Developer machine, VM, or host

Debian and Ubuntu on `x86_64` / `amd64` are supported. The standard route is:

```sh
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/scripts/bootstrap/entrypoint.sh | bash
```

It runs the same checked-in implementation as `just bootstrap auto`; the curl
script only creates or updates the checkout. If Git is not installed, it first
uses the public GitHub source archive, then the system layer installs Git when
privileges permit. It does not contain package or runtime installation logic.
`HOMEUP_REPO_URL`, `HOMEUP_REF`, and `HOMEUP_DIR` are supported overrides;
without Git, a non-GitHub source additionally needs `HOMEUP_ARCHIVE_URL`.

For an existing checkout, install layers explicitly when useful:

```sh
just system::install     # root or non-interactive sudo only
just language::install   # user-owned paths by default
just user::apply         # locked CLI + chezmoi
```

The language layer downloads locked prebuilt runtime archives, including
CPython, and verifies their SHA-256 digests. It does not compile languages on
the target machine.

## Fresh persistent host

Host operations are optional and independent from the development layers:

```sh
NEW_USER=dev SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" just host::provision
```

Log in as that user from a separate terminal before considering:

```sh
just host::ssh-harden
```

The latter is never included in a bootstrap, cloud-init template, image, or
automatic workflow.

## Other carriers

### cloud-init

`cloud-init/homeup.yaml.tmpl` is a template, not a ready-to-upload file. Render
it on a trusted machine with explicit values, then review the output before
using it as instance user-data:

```sh
export HOMEUP_USER=dev
export HOMEUP_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
export HOMEUP_REPO_URL=https://github.com/zopiya/homeup.git
export HOMEUP_HOSTNAME=homeup-dev
export HOMEUP_TIMEZONE=UTC
export HOMEUP_ENABLE_UFW=false
envsubst < cloud-init/homeup.yaml.tmpl >homeup-cloud-init.yaml
```

The template creates the user and key through cloud-init, then runs the same
system, language, and user layers. It never enables SSH hardening. Do not put
access tokens or private keys in user-data.

### Docker, Dev Containers, and Codespaces

`containers/dev/Dockerfile` builds the `linux/amd64` development image with the
system and language layers. The checked-in Dev Container references its
published GHCR image by immutable digest and runs `just user::apply` as the
non-root `dev` user after creation.

For a local image check:

```sh
docker build --file containers/dev/Dockerfile --tag homeup-dev:local .
docker run --rm --user dev homeup-dev:local bash -lc 'just doctor'
```

See the [v1 environment contract](dev-environment-v1.md) for lifecycle and
provenance details.
