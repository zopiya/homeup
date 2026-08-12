# Homeup Linux contributor guide

Homeup is a personal, reproducible development environment for Debian and
Ubuntu on `amd64`. It supports hosts and VMs, cloud-init, Docker, Dev
Containers, and GitHub Codespaces through the same three layers:

1. **System** installs Debian/Ubuntu packages and requires root or
   passwordless sudo.
2. **Language** installs the locked Python, Node.js, Bun, and Rust toolchains.
3. **User** installs locked CLI tools and applies chezmoi-managed dotfiles.

The accepted design contract is [docs/dev-environment-v1.md](docs/dev-environment-v1.md).
Keep the implementation and public documentation consistent with it.

## Safety boundaries

- Support Debian and Ubuntu on `x86_64` / `amd64` only. Do not add version
  managers or compile language runtimes on target machines.
- `toolchain/lock.sh` is the single source of truth for non-apt artifacts.
  Downloads must be checksum-verified and must not use a `latest` URL.
- Host provisioning is separate from bootstrap. `host::ssh-harden` must remain
  interactive and must never be called by bootstrap, cloud-init, or an image.
- Git identity is opt-in via `HOMEUP_GIT_*`; never commit credentials, keys, or
  personal identity into images or generated cloud-init data.
- The Dev Container image contains only system and language layers. User
  dotfiles are applied after the non-root user exists.

## Public interface

```sh
just bootstrap [auto]
just bootstrap full
just bootstrap user
just system::install
just language::install
just user::apply
just doctor
just host::provision
just host::ssh-harden
```

Do not add compatibility aliases or parallel installers without a documented
migration need. The curl entry point is deliberately thin and delegates to the
checked-in bootstrap implementation.

## Change and verification checklist

- Shell: use `set -euo pipefail`, quote variables, run ShellCheck and shfmt.
- Dotfiles/templates: run `just validate` after changes.
- Locked artifacts: run `scripts/ci/validate-lock.sh` after changes.
- Bootstrap, container, or cloud-init changes: update the relevant docs and
  test on the closest available carrier.
- Keep commit messages in conventional format:
  `<type>(<scope>): <description>`.
