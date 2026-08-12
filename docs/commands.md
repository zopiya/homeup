# Command reference

The v1 public interface is deliberately small:

```sh
just bootstrap [auto]   # system when permitted, then language + user
just bootstrap full     # require root or non-interactive sudo
just bootstrap user     # no sudo and no apt
just system::install
just language::install
just user::apply
just doctor
just host::provision
just host::ssh-harden   # manual only
```

`auto` uses the system layer only when the current process is root or has
passwordless/non-interactive sudo. `full` fails before changing anything if it
cannot use system access. `user` is safe on a host where the user has no sudo.

`just host::provision` is for a new persistent machine. It requires explicit
`NEW_USER` and `SSH_PUBKEY`; it can configure UFW, hostname, and timezone but
never invokes SSH hardening. Confirm a separate SSH login before manually
running `just host::ssh-harden`.

## Variables

| Variable | Meaning |
| --- | --- |
| `HOMEUP_REPO_URL` | public checkout URL override for the curl entry point |
| `HOMEUP_DIR` | checkout path override; default is `~/.local/share/homeup-linux` |
| `HOMEUP_GIT_NAME` | optional Git user name injected by chezmoi |
| `HOMEUP_GIT_EMAIL` | optional Git email injected by chezmoi |
| `HOMEUP_GIT_SIGNING_KEY` | optional SSH signing public key |
| `HOMEUP_GIT_SIGN_COMMITS` | set to `true` to enable SSH commit signing |
| `NEW_USER`, `SSH_PUBKEY` | required only for host provisioning |
| `NEW_HOSTNAME`, `TIMEZONE`, `EXTRA_FIREWALL_PORTS` | optional host-provisioning values |

The previous `provision`, `install`, `apply`, and `scripts::*` recipes remain
as compatibility aliases during the v1 migration. New automation must use the
v1 commands above.
