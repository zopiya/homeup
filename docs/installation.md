# Installation reference

Manual walkthrough and known caveats for the two-phase install described in the
[README](../README.md). See [architecture.md](architecture.md) for the directory layout and
[commands.md](commands.md) for the full `just`/script/env-var reference.

## Prerequisites

- A fresh Debian 12+ or Ubuntu 22.04+ server, root/sudo access
- Your SSH public key (e.g. `cat ~/.ssh/id_ed25519.pub` on your workstation)
- Git — not required for `root-install.sh`/`install.sh` (they install it themselves if missing),
  only for the fully manual walkthrough below

## Fully manual — run every step yourself

```bash
# ── Day 0 (as root) ──────────────────────────────────────────────────────────
git clone https://github.com/zopiya/homeup-linux.git /tmp/homeup-linux && cd /tmp/homeup-linux
sudo bash packages/server-init.sh
# Follow the prompts. It stops before disabling root/password login and asks
# you to verify the new user can log in from a SEPARATE terminal first —
# don't skip that check, or you can lock yourself out.

# ── Day 1 (as your new user, after logging back in) ─────────────────────────
sudo mkdir -p /opt/homeup-linux && sudo chown "$(id -u):$(id -g)" /opt/homeup-linux
git clone https://github.com/zopiya/homeup-linux.git /opt/homeup-linux
cd /opt/homeup-linux

# just/chezmoi aren't installed yet, so install packages directly first:
sudo apt-get update && xargs -a packages/apt-packages.txt sudo apt-get install -y
bash packages/install-tools.sh   # installs chezmoi, just, starship, neovim, ...

# Now chezmoi/just exist — apply dotfiles (--dry-run first to preview)
chezmoi init --source /opt/homeup-linux --apply --dry-run
chezmoi init --source /opt/homeup-linux --apply

# Finish setup (default shell, sheldon lock, gpg-agent)
just setup
```

On any later server, once `just` is already present (e.g. re-running `packages/install-tools.sh`
first), `just bootstrap` does the same three manual steps in one shot.

## Known caveats

- **Passwordless sudo**: `server-init.sh` creates `$NEW_USER` with `adduser --disabled-password`
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
