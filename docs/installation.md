# Installation reference

Manual walkthrough and known caveats for the two-phase install described in the
[README](../README.md). See [architecture.md](architecture.md) for the directory layout and
[commands.md](commands.md) for the full `just`/script/env-var reference.

## Prerequisites

- A fresh Debian or Ubuntu server, root/sudo access. Core support is Debian 12/13 and Ubuntu
  24.04/26.04 — `scripts/init.sh`/`scripts/install.sh` warn (but don't block) on any other version
- Your SSH public key (e.g. `cat ~/.ssh/id_ed25519.pub` on your workstation)
- Git — not required for `scripts/init.sh`/`scripts/install.sh` (they install it themselves if
  missing), only for the fully manual walkthrough below

## Fully manual — run every step yourself

```bash
# ── Day 0 (as root) ──────────────────────────────────────────────────────────
git clone https://git.zopiya.dev/infra/homeup-linux.git /tmp/homeup-linux && cd /tmp/homeup-linux
sudo bash scripts/system/create-user.sh
sudo bash scripts/system/ufw.sh
sudo bash scripts/system/hostname.sh
sudo bash scripts/system/timezone.sh
# Each is independent and safe to re-run. Now open a SEPARATE terminal and
# confirm you can log in as the new user — don't skip that check, or the
# next command (whenever you choose to run it) can lock you out:
#   sudo bash scripts/system/ssh-harden.sh

# ── Day 1 (as your new user, after logging back in) ─────────────────────────
sudo mkdir -p /opt/homeup && sudo chown "$(id -u):$(id -g)" /opt/homeup
git clone https://git.zopiya.dev/infra/homeup-linux.git /opt/homeup
cd /opt/homeup

# just/chezmoi aren't installed yet, so install packages directly first:
sudo apt-get update && grep -v '^#' scripts/packages/apt-packages.txt | xargs sudo apt-get install -y
bash scripts/packages/install-tools.sh   # installs chezmoi, just, starship, neovim, ...

# Now chezmoi/just exist — apply dotfiles (--dry-run first to preview).
# sheldon lock / gpg-agent reload run automatically as chezmoi hooks during
# this apply — no separate `just setup` needed for those anymore.
chezmoi init --source /opt/homeup --apply --dry-run
chezmoi init --source /opt/homeup --apply

# Finish setup (default shell only, at this point)
just setup
```

On any later server, once `just` is already present (e.g. re-running
`scripts/packages/install-tools.sh` first), `just provision` does the four Day 0 scripts above in
one shot (SSH hardening stays separate — `just scripts::ssh-harden`, always manual), and
`just bootstrap` does the three Day 1 steps in one shot.

## Known caveats

- **Passwordless sudo**: `create-user.sh` creates `$NEW_USER` with `adduser --disabled-password`
  (SSH-key-only login, no password at all) and grants it `NOPASSWD` sudo via a dedicated
  `/etc/sudoers.d/$NEW_USER` drop-in. Without this, `sudo` would be unusable for that account in any
  context — there's no password it could ever type that PAM would accept. This doesn't expand what
  the account can do (it was already in the `sudo` group, i.e. full root via sudo); it only removes
  the password prompt. If you'd rather keep password-gated sudo, delete that file after provisioning
  and set a real password with `sudo passwd $NEW_USER` (unrelated to SSH login, which stays key-only).
- **`bat`/`fd`**: Debian/Ubuntu package these as `batcat`/`fdfind` to avoid name clashes.
  `install-tools.sh` symlinks `bat`/`fd` into `~/.local/bin` so this config's aliases work as-is.
- **Commit signing**: `dot_config/git/identity.gitconfig.tmpl` carries the same SSH signing key as
  homeup. If the matching private key isn't present on this server, `git commit` will fail to sign
  — either copy the signing key over or run `git config commit.gpgsign false` locally.
- **Architecture**: `install-tools.sh` only supports `x86_64`/`amd64` and exits with a clear error
  on other architectures rather than silently installing binaries that won't run. On an arm64
  server, edit the GitHub-release patterns (swap in `aarch64`/`arm64`) before running it.
- **tmux plugins**: `install-tools.sh` clones TPM, but TPM itself only installs the declared
  plugins (`tmux-resurrect`, `tmux-continuum`, ...) the first time you press `prefix + I` inside a
  tmux session — do that once after the first `chezmoi apply`.
