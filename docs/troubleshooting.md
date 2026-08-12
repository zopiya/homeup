# Troubleshooting

## Start with the environment report

Run this from the checkout (or from Homeup's default checkout directory):

```sh
just doctor
```

It reports the carrier, privilege level, and whether each locked runtime and
CLI matches `toolchain/lock.sh`.

## The system layer was skipped

`just bootstrap auto` skips the system layer when the current user has neither
root nor passwordless sudo. This is expected; language and user layers still
run. To install system packages, use an account with the required access:

```sh
just bootstrap full
```

`full` fails before changing the machine if that access is unavailable.

## A download or checksum check failed

Homeup refuses to install an artifact with an unexpected SHA-256 digest. Do not
bypass this check. Retry after checking network access; if the failure persists,
inspect the locked URL and digest in `toolchain/lock.sh` and update them only
through the reviewed toolchain update workflow.

To discard a partial download cache, remove only this user-owned directory and
run the command again:

```sh
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/homeup/downloads"
```

## An existing checkout cannot be updated

The curl entry point refuses to overwrite an unmanaged directory and uses
`git pull --ff-only` for an existing Git checkout. Preserve your work first,
then resolve the checkout manually:

```sh
git -C ~/.local/share/homeup-linux status
git -C ~/.local/share/homeup-linux pull --ff-only
```

If the checkout was intentionally customized, use a different `HOMEUP_DIR`
instead of replacing it.

## Dotfiles did not apply as expected

Preview changes before applying them:

```sh
chezmoi diff
just user::apply
```

Git identity is intentionally absent unless `HOMEUP_GIT_NAME` and
`HOMEUP_GIT_EMAIL` are set before applying the user layer. This prevents a
container or Codespace from inheriting personal identity settings.

## SSH hardening

Do not run `just host::ssh-harden` until a separate SSH session has confirmed
that the new user and key work. The command requires a TTY and a literal `yes`;
it never runs automatically.
