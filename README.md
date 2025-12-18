# 🚀 Homeup - Modern Dotfiles

<div align="center">

![License](https://img.shields.io/github/license/zopiya/dotfiles?style=flat-square)
![Chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-0055FF?style=flat-square&logo=chezmoi)
![Neovim](https://img.shields.io/badge/editor-neovim-57A143?style=flat-square&logo=neovim)
![Zsh](https://img.shields.io/badge/shell-zsh-F15A24?style=flat-square&logo=zsh)

[English](README.md) | [简体中文](README_zh-CN.md) | [Architecture Doc (CN)](ARCHITECTURE_zh-CN.md)

</div>

**Homeup** is a highly modular, cross-platform, and automated development environment configuration system built with pragmatism at its core. It leverages modern tools to provide a reproducible and fast setup experience for macOS and Linux.

> **Philosophy**: "Aim high, act pragmatically" - Designed with future extensibility in mind, but only implements what's essential today.

## ✨ Features

- **⚡️ Fast Bootstrap**: Go from bare metal to a fully functional environment in ~15 minutes.
- **🍎🐧 Cross-Platform**: Seamless support for macOS (Apple Silicon/Intel) and Linux (Debian/Fedora/Ubuntu).
- **🧩 Modular Design**: Profile-based setup (Workstation/Server/Minimal) with granular module control.
- **🔒 Security First**: Optional YubiKey + GPG + 1Password integration for credential management.
- **🛠 Modern Stack**: Community-proven tools - Homebrew, Mise, Starship, Neovim, Sheldon.
- **🔄 Configuration as Code**: Single Git repository managing all dotfiles with template-based customization.

## � Use Cases

| Scenario                      | Profile     | Modules Enabled                                    | Setup Time |
| ----------------------------- | ----------- | -------------------------------------------------- | ---------- |
| **Primary MacBook**           | Workstation | Core + GUI + Fonts + Mise + Security + Maintenance | ~15 min    |
| **Remote Linux Server**       | Server      | Core + Mise + Maintenance                          | ~8 min     |
| **Docker Container**          | Manual      | Core only                                          | ~3 min     |
| **Work Machine (Restricted)** | Manual      | Core + GUI (no Security)                           | ~10 min    |
| **Raspberry Pi**              | Server      | Core + Mise                                        | ~10 min    |

## 🏗 Architecture

The project follows a **4-layer modular architecture**:

```
┌─────────────────────────────────────────────┐
│  Layer 3: Maintenance (Optional)            │
│  Topgrade, Restic                           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 2: Runtimes (Optional)               │
│  Mise → Python, Node.js, Rust, Go           │
│  uv, pnpm, cargo                            │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 1: User Environment (Modular)        │
│  ┌──────────────────────────────────────┐   │
│  │ Core Module (Required)               │   │
│  │ Git, Zsh, Neovim, Starship, Sheldon  │   │
│  └──────────────────────────────────────┘   │
│  ┌──────────────────────────────────────┐   │
│  │ GUI Module (Optional)                │   │
│  │ VSCode, Browser, Terminal Emulator   │   │
│  └──────────────────────────────────────┘   │
│  ┌──────────────────────────────────────┐   │
│  │ Security Module (Optional)           │   │
│  │ YubiKey, GPG, 1Password              │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 0: Bootstrap (Essential)             │
│  Install Homebrew + Chezmoi                 │
└─────────────────────────────────────────────┘
```

### Core Technologies

- **Configuration Management**: [Chezmoi](https://www.chezmoi.io/) - Template-based dotfile manager
- **Package Management**: [Homebrew](https://brew.sh/) - Universal package manager for macOS/Linux
- **Runtime Management**: [Mise](https://mise.jdx.dev/) - Fast, polyglot version manager
- **Shell**: Zsh + [Sheldon](https://sheldon.cli.rs/) (plugin manager) + [Starship](https://starship.rs/) (prompt)
- **Editor**: [Neovim](https://neovim.io/) - Modern vim with Lua configuration (Lazy.nvim)
- **Security**: YubiKey + GPG + 1Password CLI (optional)

## 📂 Directory Structure

```
├── bootstrap.sh          # Entry point for installation
├── data/                 # Package lists (Brewfile, Flatpak)
├── dot_bashrc.tmpl       # Bash configuration
├── dot_zshenv.tmpl       # Zsh environment variables
├── dot_config/           # XDG Config Home
│   ├── git/              # Git config
│   ├── mise/             # Runtime versions
│   ├── nvim/             # Neovim config
│   ├── security/         # Security tools (GPG, YubiKey)
│   ├── sheldon/          # Zsh plugins
│   ├── starship.toml     # Prompt config
│   ├── topgrade.toml     # Update utility config
│   └── zsh/              # Zsh config (ZDOTDIR)
├── dot_local/            # Local binaries and scripts
├── private_dot_gnupg/    # GPG configuration
└── private_dot_ssh/      # SSH config template
```

## 🚀 Quick Start

### One-Command Bootstrap

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zopiya/dotfiles/main/bootstrap.sh)
```

**What happens**:

1. Detects OS (macOS/Linux) and architecture (x86/ARM)
2. Installs system dependencies (Linux only)
3. Installs Homebrew
4. Installs Chezmoi via Homebrew
5. Runs `chezmoi init --apply` with interactive setup

### Interactive Setup

During initialization, you'll be asked to:

```
👋 Welcome to homeup Setup

1. Identity Configuration
   Git Name: Your Name
   Git Email: your@email.com

2. Machine Profile
   [1] workstation  (macOS/Linux GUI) - Core + GUI + Fonts + Runtime + Maint
   [2] server       (Headless)        - Core + Runtime + Maint
   [9] manual       (Custom)          - Custom selection
   Select Profile: 1

3. Security Module
   Install Security tools? (YubiKey/GPG/1Password) [y/N]: n

📝 Configuration Summary:
   Git User:    Your Name <your@email.com>
   Profile:     workstation
   Modules:
     [x] Core CLI (Base)
     [x] GUI Applications
     [x] Fonts
     [x] Mise Runtime
     [x] Maintenance Tools
     [ ] Security Suite
     [ ] Security Suite
```

### Post-Installation

```bash
# Restart shell to apply changes
exec zsh

# Verify installation
chezmoi doctor
starship --version
nvim --version
```

## 📂 Project Structure

```
~/.local/share/chezmoi/
├── bootstrap.sh              # Entry point for new machines
├── .chezmoi.toml.tmpl        # Interactive config generator (not in Git)
├── .chezmoiignore.tmpl       # Conditional file exclusions
│
├── data/
│   └── Brewfile.tmpl         # Modular package definitions
│
├── dot_config/               # XDG Config Home (~/.config)
│   ├── git/
│   │   ├── config.tmpl
│   │   ├── aliases.gitconfig
│   │   └── identity.gitconfig.tmpl
│   ├── mise/
│   │   └── config.toml       # Global runtime versions
│   ├── nvim/                 # Neovim configuration
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── core/         # Options & keymaps
│   │       ├── plugins/      # Plugin specs
│   │       └── config/       # Plugin configs
│   ├── sheldon/
│   │   └── plugins.toml      # Zsh plugin manager
│   ├── starship.toml         # Cross-shell prompt
│   ├── topgrade.toml         # Update automation
│   ├── zsh/
│   │   ├── aliases.zsh
│   │   ├── exports.zsh.tmpl
│   │   ├── functions.zsh
│   │   └── dot_zshrc.tmpl
│   └── security/             # Security module configs
│       ├── yubikey.inc.tmpl
│       ├── gpg.inc.tmpl
│       └── 1password.inc.tmpl
│
├── dot_local/
│   └── bin/
│       └── executable_restic_backup.sh.tmpl
│
├── private_dot_ssh/
│   └── config.tmpl           # SSH client configuration
│
├── private_dot_gnupg/        # GPG configs (if Security enabled)
│   ├── gpg.conf
│   └── gpg-agent.conf.tmpl
│
└── .chezmoiscripts/          # Automated setup scripts
    ├── run_once_before_10_check_prerequisites.sh.tmpl
    ├── run_once_20_install_system_packages.sh.tmpl
    ├── run_once_30_install_security_tools.sh.tmpl
    ├── run_once_40_install_runtimes.sh.tmpl
    ├── run_once_50_install_gui_apps.sh.tmpl
    ├── run_once_60_configure_shell.sh.tmpl
    ├── run_once_70_setup_maintenance.sh.tmpl
    └── run_after_99_finalize.sh.tmpl
```

## 🔧 Daily Usage

### Editing Configurations

```bash
# ✅ Correct way (edits source, auto-syncs)
chezmoi edit ~/.zshrc

# ❌ Wrong way (creates drift)
vim ~/.zshrc
```

### Applying Changes

```bash
# Preview changes
chezmoi diff

# Apply to system
chezmoi apply -v

# Verify consistency
chezmoi verify
```

### Syncing Across Machines

```bash
# Pull latest from Git
chezmoi update

# Push local changes
chezmoi cd
git add .
git commit -m "feat: add new alias"
git push
```

### Managing Runtimes (if Mise enabled)

```bash
# Install global tools
mise use --global python@3.12 node@20

# Project-specific versions
cd ~/projects/my-app
mise use python@3.11 node@18

# Check current versions
mise current
```

## ⚙️ Customization

### Fork and Personalize

1. **Fork** this repository
2. Clone and initialize:
   ```bash
   chezmoi init --apply your-username
   ```
3. Modify configurations:
   - `data/Brewfile.tmpl` - Add/remove packages
   - `dot_config/zsh/aliases.zsh` - Custom aliases
   - `dot_config/nvim/lua/plugins/init.lua` - Neovim plugins

### Advanced: Module Selection

Edit `.chezmoi.toml.tmpl` to change default module behavior:

```toml
{{- $install_gui := promptBool "Install GUI apps?" true -}}
{{- $install_mise := promptBool "Install Mise?" true -}}
```

## 🔒 Security Best Practices

### Secret Management

- ✅ **DO**: Use 1Password CLI or Bitwarden for secrets
- ✅ **DO**: Store GPG keys in YubiKey
- ❌ **DON'T**: Commit `.chezmoi.toml` (contains machine-specific data)
- ❌ **DON'T**: Hardcode tokens in dotfiles

### Example: 1Password Integration

```toml
# dot_config/gh/config.yml.tmpl
github.com:
  user: {{ .github_username }}
  oauth_token: {{ onePasswordRead "op://Private/GitHub/token" }}
```

## 🐛 Troubleshooting

| Issue                       | Solution                                             |
| --------------------------- | ---------------------------------------------------- |
| `command not found: brew`   | Restart shell: `exec zsh`                            |
| `chezmoi: template error`   | Check syntax: `chezmoi execute-template < file.tmpl` |
| Zsh slow startup (>0.5s)    | Profile: `zsh -xv` and optimize plugin loading       |
| GPG signing fails           | Import keys: `gpg --import ~/.gnupg/pubring.gpg`     |
| Mise not switching versions | Check `.mise.toml` in project directory              |

Run health check:

```bash
chezmoi doctor
```

## 🤝 Contributing

Contributions welcome! Please:

1. Follow existing code style
2. Test on both macOS and Linux if possible
3. Update documentation for new features

## 📚 Further Reading

- [ARCHITECTURE_zh-CN.md](ARCHITECTURE_zh-CN.md) - Comprehensive architecture guide (Chinese)
- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Mise Documentation](https://mise.jdx.dev/)

## 📜 License

MIT - Feel free to use this as a template for your own dotfiles!
