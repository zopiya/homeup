# Homeup

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![chezmoi](https://img.shields.io/badge/powered%20by-chezmoi-blue)](https://www.chezmoi.io/)

Opinionated dotfiles for macOS & Linux with multi-profile support.

## Features

- **Multi-Profile** - Workstation, Codespace, Server configurations
- **Cross-Platform** - macOS and Linux (Debian, Fedora, Arch, Alpine)
- **Secure** - Profile-based secret isolation, no private keys in repo
- **YubiKey-Ready** - GPG signing and SSH authentication support
- **One Command** - Fully automated bootstrap process

## Quick Start

```bash
# Interactive (auto-detects profile)
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash

# Specify profile
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash -s -- -p workstation -r zopiya/homeup -a
```

### Manual Installation

```bash
# 1. Install chezmoi and initialize
chezmoi init https://github.com/zopiya/homeup.git

# 2. Review changes
chezmoi diff

# 3. Apply
chezmoi apply
```

## Profiles

| Profile | Trust Level | Use Case | Features |
|---------|-------------|----------|----------|
| **workstation** | Full | Personal machine | GPG signing, YubiKey, GUI apps, all packages |
| **codespace** | Borrowed | Dev containers | SSH forwarding, CLI tools, no GPG |
| **server** | Zero | Production/CI | Minimal packages, no private keys |

Set profile via environment variable:
```bash
export HOMEUP_PROFILE=workstation
```

## What's Included

| Category | Tools |
|----------|-------|
| Shell | zsh, starship, sheldon, fzf, atuin, zoxide |
| Editor | neovim, tmux, zellij |
| Git | git, gh, lazygit, delta |
| Modern Unix | bat, eza, fd, ripgrep, jq, yq, dust |
| Runtime | mise, uv, pnpm |
| Security | gnupg, age, 1password-cli, ykman |

## Structure

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

## Customization

```bash
# Edit packages
chezmoi edit packages/Brewfile.macos

# Edit git identity
chezmoi edit dot_config/git/identity.gitconfig.tmpl

# Apply changes
chezmoi apply
```

## License

MIT
