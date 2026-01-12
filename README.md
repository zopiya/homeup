# Homeup

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![chezmoi](https://img.shields.io/badge/powered%20by-chezmoi-blue)](https://www.chezmoi.io/)
[![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-green)](#profiles)

Opinionated dotfiles for macOS & Linux with multi-profile safety, YubiKey-ready security, and a one-command bootstrap (script v6.0.0).

## Quick Links
- [Why Homeup](#why-homeup)
- [Profiles](#profiles)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Security Defaults](#security-defaults)
- [What's Inside](#whats-inside)
- [Project Layout](#project-layout)
- [Customize](#customize)
- [Developer Tasks](#developer-tasks)
- [License](#license)

## Why Homeup
- **Multi-profile**: Workstation, Codespace, and Server tracks keep trust boundaries clear.
- **Cross-platform**: macOS plus Debian/Fedora/Arch/Alpine Linux with auto detection and sensible defaults.
- **Secure-first**: No private keys in repo; profile-based secret isolation and credential TTLs baked in.
- **YubiKey-ready**: GPG signing + SSH auth paths ready for hardware keys.
- **One-command bootstrap**: `curl | bash` installer sets up Homebrew, chezmoi, and profile packages.
- **Reviewable setup**: Chezmoi templates and `just` tasks make it easy to diff before applying.

## Profiles

| Profile | Trust Model | Use On | Highlights |
|---------|-------------|--------|------------|
| **workstation** | Full | Personal laptop/desktop | GPG signing, YubiKey, GUI apps, full package set |
| **codespace** | Borrowed | Dev containers / temporary hosts | SSH forwarding, CLI tools, no GPG |
| **server** | Zero | Production / CI | Minimal packages, no private keys or GUI |

Set a profile via environment variable or installer flag:

```bash
export HOMEUP_PROFILE=workstation     # environment override
./bootstrap.sh -p server              # CLI flag
```

## Quick Start

```bash
# Interactive (auto-detects profile)
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash

# Specify profile and auto-apply chezmoi
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash -s -- -p workstation -r zopiya/homeup -a
```

> Initialization is restricted to GitHub by default. To allow other sources, set `HOMEUP_ALLOW_UNTRUSTED_REPO=1`.

## Bootstrap Commands

- Interactive with auto-detect: `./bootstrap.sh`
- Force profile: `./bootstrap.sh -p workstation`
- Override repo + auto-apply: `./bootstrap.sh -p workstation -r zopiya/homeup -a`
- Non-interactive/CI friendly: `./bootstrap.sh -p server -r zopiya/homeup -a -y`
- Run from remote: `curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash -s -- -p codespace -r zopiya/homeup`

## Installation

- **Requirements**: `bash`, `curl`, `git` (bootstrap will install Homebrew + chezmoi automatically when missing).
- **Non-interactive**: `./bootstrap.sh -p server -r zopiya/homeup -a -y` (suitable for CI/remote).
- **Manual (chezmoi)**:
  ```bash
  # 1) Initialize
  chezmoi init https://github.com/zopiya/homeup.git

  # 2) Review
  chezmoi diff

  # 3) Apply
  chezmoi apply
  ```

## Security Defaults

- SSH agent: workstation uses `ForwardAgent ask` (prompt per connection); codespace/server disable forwarding.
- SSH CA: to trust an SSH CA, place the CA public key at `~/.ssh/ssh_ca.pub` on the target host (workstation clients can manage this manually).
- Credential cache TTL: workstation 900s; codespace/server 60s.
- Sensitive payloads: non-workstation profiles skip syncing `.gnupg/**` and `.config/security/*.inc`.

## What's Inside

| Category | Tools |
|----------|-------|
| Shell | zsh, starship, sheldon, fzf, atuin, zoxide |
| Editor | neovim, tmux, zellij |
| Git | git, gh, lazygit, delta |
| Modern Unix | bat, eza, fd, ripgrep, jq, yq, dust |
| Runtime | mise, uv, pnpm |
| Security | gnupg, age, 1password-cli, ykman |

## Project Layout

```
homeup/
├── bootstrap.sh                 # Layer 0: Environment setup
├── .chezmoiscripts/             # Layer 1: Package installation
├── packages/
│   ├── Brewfile.core            # Shared CLI tools (all profiles)
│   ├── Brewfile.macos           # macOS workstation
│   ├── Brewfile.linux           # Linux workstation
│   ├── Brewfile.codespace       # Codespace additions
│   ├── Brewfile.server          # Server additions
│   └── flatpak.txt              # Linux GUI apps
├── dot_config/
│   ├── git/                     # Git configuration
│   ├── zsh/                     # Zsh configuration
│   ├── nvim/                    # Neovim configuration
│   └── security/                # GPG, 1Password, YubiKey
├── private_dot_ssh/             # SSH configuration
└── private_dot_gnupg/           # GPG configuration
```

## Customize

```bash
# Edit package lists
chezmoi edit packages/Brewfile.macos

# Update git identity template
chezmoi edit dot_config/git/identity.gitconfig.tmpl

# Apply changes locally
chezmoi apply
```

## Developer Tasks

- `just diff` — review templated changes before applying.
- `just apply` / `just apply-verbose` — apply dotfiles.
- `just validate` — dry-run all profiles with `chezmoi init --dry-run`.
- `just install-hooks` — install lefthook-managed git hooks.
- `just clean` — purge chezmoi cache and temp test directories.

## License

MIT
