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

Use `cloud-init/homeup.yaml.tmpl` only after rendering its required named
values. The Docker image is defined by `containers/dev/Dockerfile`; it prepares
the system and language layers as root and leaves dotfiles for the non-root
post-create user layer. See `docs/dev-environment-v1.md` for lifecycle details.
