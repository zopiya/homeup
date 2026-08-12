# Installation guide

## Developer machine, VM, or host

Debian and Ubuntu on `amd64` and `arm64` are supported. The standard route is:

```sh
curl -fsSL https://get.zopiya.dev/dev | bash
```

It runs the same checked-in implementation as `just bootstrap auto`; the curl
script only creates or updates the checkout. It does not contain package or
runtime installation logic.

For an existing checkout, install layers explicitly when useful:

```sh
just system::install     # root or non-interactive sudo only
just language::install   # user-owned paths by default
just user::apply         # locked CLI + chezmoi
```

The language layer builds CPython where needed and therefore needs the build
packages from the system layer. A no-sudo machine without those prerequisites
fails with a diagnostic rather than installing an unpinned fallback.

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

Use `cloud-init/homeup.yaml.tmpl` only after rendering its required named
values. The Docker image is defined by `containers/dev/Dockerfile`; it prepares
the system and language layers as root and leaves dotfiles for the non-root
post-create user layer. See `docs/dev-environment-v1.md` for lifecycle details.
