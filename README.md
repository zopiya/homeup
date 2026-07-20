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

```bash
# ── Day 0 (as root) ──────────────────────────────────────────────────────────
git clone https://github.com/zopiya/homeup-linux.git /tmp/homeup-linux && cd /tmp/homeup-linux
sudo bash packages/server-init.sh
# Follow the prompts. It stops before disabling root/password login and asks
# you to verify the new user can log in from a SEPARATE terminal first —
# don't skip that check, or you can lock yourself out.

# ── Day 1 (as your new user, after logging back in) ─────────────────────────
curl -fsSL https://xx.zopiya.dev/init.sh | bash
```

`install.sh` is the one-shot version of Day 1: it clones (or updates) the repo into
`~/workspace/homeup-linux`, installs apt packages + upstream tools, applies dotfiles via chezmoi,
and runs `just setup` — all in one non-interactive pass. It's also how you update later: run the
same command again and it pulls the latest commit, re-applies dotfiles, and re-runs the installers
(which already skip anything that's up to date). Override `HOMEUP_REPO_URL`/`HOMEUP_DIR` env vars
to point at a fork or a different checkout path.

If you'd rather run each step yourself (e.g. to review before applying), the manual sequence is:

```bash
git clone https://github.com/zopiya/homeup-linux.git ~/workspace/homeup-linux
cd ~/workspace/homeup-linux

# just/chezmoi aren't installed yet, so install packages directly first:
sudo apt-get update && xargs -a packages/apt-packages.txt sudo apt-get install -y
bash packages/install-tools.sh   # installs chezmoi, just, starship, neovim, ...

# Now chezmoi/just exist — apply dotfiles (--dry-run first to preview)
chezmoi init --source ~/workspace/homeup-linux --apply --dry-run
chezmoi init --source ~/workspace/homeup-linux --apply

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
├── install.sh                  # One-shot Day 1 bootstrap (curl | bash friendly, re-run to update)
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
| `NEW_USER` | `zopiya` | `server-init.sh`: username to create |
| `SSH_PUBKEY` | (prompted) | `server-init.sh`: public key to install for `NEW_USER` |
| `TIMEZONE` | `Asia/Shanghai` | `server-init.sh`: timezone to set |
| `EXTRA_FIREWALL_PORTS` | (empty) | `server-init.sh`: extra ufw ports beyond SSH |
| `HOMEUP_REPO_URL` | `https://github.com/zopiya/homeup-linux.git` | `install.sh`: repo to clone (e.g. point at a fork) |
| `HOMEUP_DIR` | `~/workspace/homeup-linux` | `install.sh`: where to clone/update the repo |

### Known caveats

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
