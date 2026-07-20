# Homeup Linux

A **headless Debian/Ubuntu server** dotfiles setup using chezmoi + apt + just — the sibling of
[homeup](https://github.com/) (macOS workstation). Same shell/tooling experience, adapted for a
freshly-provisioned cloud server with no GUI.

This repo does **not** depend on homeup at runtime — the portable pieces (zsh modules, nvim, tmux,
zellij, starship, git aliases, ...) were copied over once and are maintained independently here.

Tuned for daily ops/dev use on a box you SSH into, not sit in front of:
- Every login auto-attaches a persistent tmux session (`main`) — a dropped connection never loses
  work, and `tmux-resurrect`/`tmux-continuum` (already configured, TPM auto-installed) survive a
  reboot too. First-ever login also gets a one-time `fastfetch` system-info banner.
- The prompt always shows `user@hostname` when SSH'd in — easy to lose track of which of several
  servers a terminal is on otherwise.
- A small ops/dev toolbelt beyond the base shell: `yq` (YAML), `bottom`/`glances`/`htop` (resource
  monitoring), `xh` (HTTP client), `watchexec` (dev-loop automation), `mtr`/`dnsutils`/`tcpdump`
  (network debugging), `rclone` (backup/sync). Container/orchestration tooling (Docker, k8s) is
  intentionally left out — install those by hand on the servers that actually need them rather than
  baking one team's stack into every box.

## Two phases

Cloud servers usually start as a completely fresh machine, so getting to a working shell takes two
separate stages, run as two different users:

1. **Day 0 — provisioning (root, once)**: create a non-root sudo user, install your SSH public key,
   set hostname/timezone, open the firewall, then disable root/password SSH login.
2. **Day 1 — dotfiles (your user)**: apt packages + upstream tool installers, then chezmoi applies
   the dotfiles — same shape as homeup's bootstrap flow.

## Prerequisites

- A fresh Debian 12+ or Ubuntu 22.04+ server, root/sudo access
- Your SSH public key (e.g. `cat ~/.ssh/id_ed25519.pub` on your workstation)
- Git

## Getting Started

### Fully automatic — one command, root to working shell

```bash
export NEW_USER=zopiya SSH_PUBKEY="ssh-ed25519 AAAA... you@laptop"
curl -fsSL https://xx.zopiya.dev/root-init.sh | sudo -E bash
```

(Already logged in as literal root, not a sudo user? Drop `sudo -E` and just pipe into `bash`.)

`root-install.sh` clones the repo into `/opt/homeup-linux`, runs Day 0 provisioning non-interactively
(create `$NEW_USER`, install `$SSH_PUBKEY`, open the firewall, set hostname/timezone), hands that
checkout off to `$NEW_USER`, then cascades straight into their Day 1 bootstrap — apt packages,
upstream tools, `chezmoi apply`, `just setup`.

**SSH hardening (disabling root/password login) is deliberately never part of this.** It's the one
genuinely irreversible step here — a wrong or mistyped key means a full lockout, recoverable only
via your cloud provider's out-of-band console. The script always stops short of it and prints the
exact follow-up command; run it yourself once you've verified `ssh $NEW_USER@<server-ip>` works from
a separate terminal.

Root does root's job (user, firewall, handoff); Day 1 always runs as `$NEW_USER`, never as root.

### Update later, or bootstrap Day 1 on its own

Once Day 0 is done (by any means) and you're logged in as your user, the same script that Day 1 used
is also the updater — re-run it and it pulls the latest commit, re-applies dotfiles, and re-runs the
installers (which already skip anything up to date):

```bash
curl -fsSL https://xx.zopiya.dev/init.sh | bash
```

Override `HOMEUP_REPO_URL`/`HOMEUP_DIR` env vars (either script) to point at a fork or a different
checkout path.

### Fully manual — run every step yourself

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

## Usage

Run `just` (no arguments) to see the help menu.

### Day 0 — server provisioning

```sh
just provision   # sudo bash packages/server-init.sh (only meaningful as root)
```

### Day 1 — daily workflow

```sh
just diff      # preview pending changes
just apply     # apply changes to system
just update    # pull latest + apply
```

### Maintenance

```sh
just doctor      # health check (required + optional tools)
just upgrade     # apt update && upgrade
just clean       # apt autoremove/clean
```

### Development

```sh
just validate    # validate chezmoi templates
just lint        # shellcheck all .sh files
just fmt         # shfmt format all .sh files
```

## Project Structure

```
homeup-linux/
├── root-install.sh              # One-shot Day 0 + Day 1 (root, curl | bash friendly, no SSH hardening)
├── install.sh                   # One-shot Day 1 bootstrap (curl | bash friendly, re-run to update)
├── justfile                   # Task runner
├── lefthook.yml                # Git hooks: pre-commit + pre-push
├── .chezmoi.toml.tmpl          # Chezmoi config (user identity)
├── dot_zshenv                  # Zsh entry point
├── dot_config/                 # chezmoi-managed ~/.config/
│   ├── zsh/                    # Modular zsh config (path, options, exports, tools, aliases, functions)
│   ├── git/                    # Git config + identity/alias templates
│   ├── nvim/                   # Neovim Lua config (copied from homeup, unchanged)
│   ├── tmux/  zellij/  starship.toml  sheldon/  atuin/  lazygit/  topgrade.toml
├── private_dot_ssh/            # SSH config (chezmoi private_ prefix → deployed 0700/0600)
├── packages/
│   ├── server-init.sh          # Day 0: user/hostname/timezone/SSH hardening/firewall (root)
│   ├── apt-packages.txt        # Day 1: flat apt package list
│   └── install-tools.sh        # Day 1: upstream installers for tools apt lacks/undershoots
└── docs/
    └── linux-ops.md            # glances/bmon/lnav/mosh usage notes
```

## Configuration

### Environment variables

| Variable | Default | Description |
|----------|---------|--------------|
| `CI` | false | Skip shell changes in CI/containers |
| `NEW_USER` | `zopiya` | `server-init.sh` / `root-install.sh`: username to create |
| `SSH_PUBKEY` | (prompted; required if non-interactive) | `server-init.sh`: public key to install for `NEW_USER` |
| `NEW_HOSTNAME` | (prompted; unchanged if non-interactive) | `server-init.sh`: hostname to set |
| `TIMEZONE` | `Asia/Shanghai` | `server-init.sh`: timezone to set |
| `EXTRA_FIREWALL_PORTS` | (empty) | `server-init.sh`: extra ufw ports beyond SSH |
| `NONINTERACTIVE` | (auto-detected) | `server-init.sh`: force non-interactive (env-var-only) mode even from a real terminal |
| `HOMEUP_REPO_URL` | `https://github.com/zopiya/homeup-linux.git` | `install.sh` / `root-install.sh`: repo to clone (e.g. point at a fork) |
| `HOMEUP_DIR` | `/opt/homeup-linux` | `install.sh` / `root-install.sh`: where to clone/update the repo |

### Known caveats

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

## License

MIT License. See [LICENSE](LICENSE).
