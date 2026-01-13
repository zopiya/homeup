<div align="center">

# 🏠 Homeup

**Modern, secure, and intelligent dotfiles for macOS & Linux**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![chezmoi](https://img.shields.io/badge/powered%20by-chezmoi-blue)](https://www.chezmoi.io/)
[![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-green)](#-profiles)
[![Version](https://img.shields.io/badge/version-2.0-purple.svg)](REFACTOR_PLAN.md)
[![Bootstrap](https://img.shields.io/badge/bootstrap-v6.0.0-orange.svg)](#-quick-start)

*One command to set up your perfect development environment anywhere*

[Features](#-features) •
[Quick Start](#-quick-start) •
[Profiles](#-profiles) •
[What's Inside](#-whats-inside) •
[Documentation](#-documentation)

</div>

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 Multi-Profile Architecture
Three distinct profiles for different trust levels:
- **macOS** → Full trust with GPG & YubiKey
- **Linux** → Headless servers & remote hosts
- **Mini** → Ephemeral containers & Codespaces

</td>
<td width="50%">

### 🔒 Security First
- Zero private keys in repository
- Profile-based secret isolation
- Hardware key support (YubiKey)
- SSH CA trust anchors

</td>
</tr>
<tr>
<td>

### 🚀 One-Command Bootstrap
```bash
curl -fsSL https://raw.githubusercontent.com/\
zopiya/homeup/main/bootstrap.sh | bash
```
Auto-detects your environment and sets up everything.

</td>
<td>

### 🔧 Developer Friendly
- Reviewable changes with `chezmoi diff`
- Task automation with `just`
- Modern Unix tools everywhere
- Consistent shell experience

</td>
</tr>
<tr>
<td>

### 🌍 Cross-Platform
- macOS (Apple Silicon & Intel)
- Linux (Debian, Fedora, Arch, Alpine)
- Automatic platform detection
- Homebrew on all platforms

</td>
<td>

### ⚡ Modern Tooling
- `mise` for runtime management
- `starship` for beautiful prompts
- `neovim` with modern config
- Modern alternatives to classic Unix tools

</td>
</tr>
</table>

---

## 🎭 Profiles

Homeup adapts to your environment with three carefully designed profiles:

<table>
<thead>
<tr>
<th width="15%">Profile</th>
<th width="20%">Trust Level</th>
<th width="35%">Best For</th>
<th width="30%">Key Features</th>
</tr>
</thead>
<tbody>
<tr>
<td align="center">
<br>
<strong>🖥️ macOS</strong>
<br><br>
</td>
<td>
<strong>Full Trust</strong><br>
<sub>Your main machine</sub>
</td>
<td>
• Personal laptop/desktop<br>
• Primary workstation<br>
• Long-term use
</td>
<td>
✅ GPG signing<br>
✅ YubiKey support<br>
✅ GUI applications<br>
✅ Full toolset<br>
✅ 1Password CLI
</td>
</tr>
<tr>
<td align="center">
<br>
<strong>🐧 Linux</strong>
<br><br>
</td>
<td>
<strong>Headless</strong><br>
<sub>Remote access only</sub>
</td>
<td>
• Production servers<br>
• Linux workstations<br>
• Homelabs
</td>
<td>
✅ SSH agent forwarding<br>
✅ Full dev + ops tools<br>
✅ Container orchestration<br>
❌ No GUI apps<br>
❌ No GPG (agent forwarded)
</td>
</tr>
<tr>
<td align="center">
<br>
<strong>📦 Mini</strong>
<br><br>
</td>
<td>
<strong>Ephemeral</strong><br>
<sub>Borrowed environments</sub>
</td>
<td>
• Dev containers<br>
• GitHub Codespaces<br>
• Temporary VMs
</td>
<td>
✅ Fast setup (~5 min)<br>
✅ Essential dev tools<br>
✅ Runtime managers<br>
❌ No ops tools<br>
❌ Minimal footprint
</td>
</tr>
</tbody>
</table>

> [!WARNING]
> **Breaking Change in v2.0**: Linux profile is now **strictly headless**. Flatpak and Linux desktop apps have been removed. If you need GUI apps on Linux, manage them separately outside of Homeup.

### Profile Selection

```bash
# Auto-detect (recommended)
./bootstrap.sh

# Explicit profile
export HOMEUP_PROFILE=macos      # via environment
./bootstrap.sh -p linux          # via flag
```

---

## 🚀 Quick Start

### One-Line Installation

The fastest way to get started (auto-detects your environment):

```bash
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash
```

### Installation Options

<details>
<summary><b>📋 All Bootstrap Commands</b></summary>

```bash
# Interactive mode (recommended for first-time setup)
./bootstrap.sh

# Specify a profile explicitly
./bootstrap.sh -p macos
./bootstrap.sh -p linux
./bootstrap.sh -p mini

# Auto-apply without review (careful!)
./bootstrap.sh -p macos -a

# Non-interactive mode (perfect for CI/automation)
./bootstrap.sh -p linux -y -a

# Use a different repository
./bootstrap.sh -p macos -r yourusername/dotfiles

# From remote (one-liner for fresh systems)
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh \
  | bash -s -- -p mini -a
```

</details>

> [!NOTE]
> **Security**: By default, only GitHub repositories are allowed. To use other sources, set `HOMEUP_ALLOW_UNTRUSTED_REPO=1`.

### What Happens During Bootstrap?

1. **🔍 Environment Detection** - Identifies your OS and suggests a profile
2. **📦 Homebrew Installation** - Installs package manager if needed
3. **🔧 Chezmoi Setup** - Initializes dotfiles manager
4. **📚 Package Installation** - Installs profile-specific packages
5. **⚙️ Configuration** - Applies all dotfiles and configurations

---

## 📦 Installation

### Prerequisites

Minimal requirements (bootstrap installs the rest):
- `bash` 4.0+
- `curl` or `wget`
- `git` 2.0+

### Manual Installation with Chezmoi

If you prefer more control over the installation process:

```bash
# 1. Initialize chezmoi with this repository
chezmoi init https://github.com/zopiya/homeup.git

# 2. Preview what will change
chezmoi diff

# 3. Apply the dotfiles
chezmoi apply

# 4. Install packages (optional)
brew bundle --file=~/.local/share/chezmoi/packages/Brewfile.core
```

<details>
<summary><b>🔧 Advanced: Manual Setup Without Bootstrap</b></summary>

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install chezmoi
brew install chezmoi

# Initialize with your profile
export HOMEUP_PROFILE=macos
chezmoi init https://github.com/zopiya/homeup.git

# Review and apply
chezmoi diff
chezmoi apply
```

</details>

---

## 🔒 Security Defaults

Security is built into every layer of Homeup:

### SSH Configuration

| Profile | Agent Forwarding | Behavior |
|---------|-----------------|----------|
| **macOS** | `ForwardAgent ask` | Prompts before forwarding to each host |
| **Linux** | Enabled for `*.hs` domain | Only trusted hosts receive agent |
| **Mini** | Disabled | No agent forwarding |

### SSH Certificate Authority

Homeup supports SSH CA for centralized trust management:
- Place your CA public key at `~/.ssh/ssh_ca.pub`
- Automatically trusted across all your hosts
- No need to distribute individual public keys

### Credential Caching

| Profile | Duration | Storage |
|---------|----------|---------|
| **macOS** | 900s (15min) | macOS Keychain + GPG Agent |
| **Linux** | 60s | Memory only |
| **Mini** | 60s | Memory only |

### Secret Isolation

- ✅ **Zero private keys in repository**
- ✅ GPG directory (`.gnupg/`) excluded on non-macOS profiles
- ✅ Security configurations (`.config/security/*.inc`) only on macOS
- ✅ All secrets managed through `.chezmoiignore` templating

---

## 🛠️ What's Inside

A curated collection of modern developer tools, organized by category:

### 🐚 Shell & Terminal

<table>
<tr>
<td width="30%"><strong>Tool</strong></td>
<td width="50%"><strong>Purpose</strong></td>
<td width="20%"><strong>Profiles</strong></td>
</tr>
<tr>
<td><code>zsh</code></td>
<td>Powerful shell with rich plugin ecosystem</td>
<td>All</td>
</tr>
<tr>
<td><code>starship</code></td>
<td>Blazing fast, customizable prompt</td>
<td>All</td>
</tr>
<tr>
<td><code>sheldon</code></td>
<td>Fast, configurable shell plugin manager</td>
<td>All</td>
</tr>
<tr>
<td><code>fzf</code></td>
<td>Fuzzy finder for command history & files</td>
<td>All</td>
</tr>
<tr>
<td><code>zoxide</code></td>
<td>Smarter cd command (tracks frecency)</td>
<td>All</td>
</tr>
<tr>
<td><code>atuin</code></td>
<td>Magical shell history with sync</td>
<td>macOS, Linux</td>
</tr>
</table>

### ✏️ Editors & Multiplexers

| Tool | Purpose | Profiles |
|------|---------|----------|
| `neovim` | Modern, extensible text editor | All |
| `tmux` | Terminal multiplexer for session management | All |
| `zellij` | Modern terminal workspace | macOS, Linux |

### 🔧 Git & Version Control

| Tool | Purpose | Profiles |
|------|---------|----------|
| `git` | Version control system | All |
| `lazygit` | Beautiful terminal UI for git | All |
| `delta` | Syntax-highlighting pager for git | All |
| `gh` | GitHub CLI for issues, PRs, and more | macOS, Linux |
| `git-cliff` | Changelog generator | Linux |
| `gitleaks` | Secret scanner for repositories | Linux |

### ☁️ DevOps & Cloud Tools

| Tool | Purpose | Profiles |
|------|---------|----------|
| `k9s` | Kubernetes cluster manager | macOS, Linux |
| `lazydocker` | Docker & Docker Compose UI | macOS, Linux |
| `terraform` | Infrastructure as Code | Linux |
| `ansible` | Configuration management | Linux |
| `helm` | Kubernetes package manager | Linux |

### 🔨 Modern Unix Replacements

Better alternatives to classic Unix tools, available everywhere:

| Instead of... | Use... | Why? |
|--------------|--------|------|
| `cat` | `bat` | Syntax highlighting + git integration |
| `ls` | `eza` | Colors, icons, git status |
| `find` | `fd` | Faster, simpler syntax |
| `grep` | `ripgrep` (`rg`) | 10x faster, respects .gitignore |
| `du` | `dust` | Visual tree, sorted by size |
| `man` | `tldr` | Quick, practical examples |

### 🏃 Runtimes & Package Managers

| Tool | Purpose | Profiles |
|------|---------|----------|
| `mise` | Universal version manager (replaces asdf, nvm, etc.) | All |
| `uv` | Lightning-fast Python package manager | All |
| `pnpm` | Efficient Node.js package manager | All |

### 🔐 Security & Secrets

| Tool | Purpose | Profiles |
|------|---------|----------|
| `gnupg` | GPG encryption & signing | macOS |
| `age` | Modern encryption tool | macOS, Linux |
| `1password-cli` | 1Password CLI integration | macOS |
| `ykman` | YubiKey manager | macOS |

### 📊 Monitoring & Debugging

| Tool | Purpose | Profiles |
|------|---------|----------|
| `btop` | Beautiful system monitor | macOS, Linux |
| `glances` | Cross-platform system monitoring | Linux |
| `httpie` / `xh` | Human-friendly HTTP clients | Linux |

---

## 📂 Project Layout

Understanding the repository structure:

```
homeup/
├── 🚀 bootstrap.sh                     # One-command installer (v6.0.0)
│
├── 📦 packages/                         # Package definitions
│   ├── Brewfile.core                   # Shared tools (all profiles except mini)
│   ├── Brewfile.macos                  # macOS GUI apps & tools
│   ├── Brewfile.linux                  # Linux server & ops tools
│   └── Brewfile.mini                   # Minimal standalone set
│
├── ⚙️  .chezmoiscripts/                 # Installation scripts
│   └── run_once_install_brew_packages.sh.tmpl
│
├── 📁 dot_config/                       # ~/.config/
│   ├── git/                            # Git config (GPG signing on macOS)
│   ├── zsh/                            # Shell configuration
│   │   ├── dot_zshrc.tmpl              # Main zsh config
│   │   ├── aliases.zsh                 # Aliases & shortcuts
│   │   └── functions.zsh               # Custom functions
│   ├── nvim/                           # Neovim configuration
│   ├── tmux/                           # Tmux configuration
│   ├── starship/                       # Starship prompt
│   └── security/                       # GPG, 1Password, YubiKey (macOS only)
│
├── 🔐 private_dot_ssh/                  # ~/.ssh/ (profile-aware)
│   ├── config.tmpl                     # SSH config with agent forwarding
│   └── authorized_keys.tmpl            # SSH CA keys
│
├── 🔑 private_dot_gnupg/                # ~/.gnupg/ (macOS only)
│   └── gpg-agent.conf.tmpl             # GPG agent configuration
│
├── 🎨 .chezmoitemplates/                # Shared template partials
│   └── profile-guard.tmpl              # Profile detection logic
│
└── 📄 Configuration
    ├── .chezmoi.toml.tmpl              # Chezmoi configuration
    ├── .chezmoiignore.tmpl             # Profile-based exclusions
    ├── justfile                        # Task automation
    └── lefthook.yml                    # Git hooks
```

---

## 🎨 Customize

Homeup is designed to be easily customized to your preferences:

### 📦 Modifying Packages

```bash
# Edit packages for a specific profile
chezmoi edit packages/Brewfile.macos
chezmoi edit packages/Brewfile.linux
chezmoi edit packages/Brewfile.mini

# Apply changes
chezmoi apply
```

### ⚙️ Updating Configurations

```bash
# Edit Git configuration
chezmoi edit dot_config/git/config.tmpl
chezmoi edit dot_config/git/identity.gitconfig.tmpl

# Edit shell configuration
chezmoi edit dot_config/zsh/dot_zshrc.tmpl
chezmoi edit dot_config/zsh/aliases.zsh

# Preview changes before applying
chezmoi diff

# Apply changes
chezmoi apply
```

### 🔧 Adding Your Own Dotfiles

```bash
# Add a new dotfile to chezmoi
chezmoi add ~/.your-config-file

# Edit it through chezmoi
chezmoi edit ~/.your-config-file

# It's now tracked and will be applied on other machines
```

---

## 👨‍💻 Developer Tasks

Homeup uses `just` for task automation. Here are the most useful commands:

| Command | Description |
|---------|-------------|
| `just diff` | Preview all changes before applying |
| `just apply` | Apply dotfiles (normal mode) |
| `just apply-verbose` | Apply dotfiles with detailed output |
| `just validate` | Test all profiles for template errors |
| `just install-hooks` | Install git hooks via lefthook |
| `just clean` | Clean chezmoi cache and temp files |

<details>
<summary><b>🔍 All Available Tasks</b></summary>

Run `just --list` to see all available tasks:

```bash
$ just --list
Available recipes:
    apply              # Apply dotfiles
    apply-verbose      # Apply dotfiles with verbose output
    clean              # Clean chezmoi cache and temporary files
    diff               # Show differences between current and target state
    install-hooks      # Install git hooks
    profile            # Show current profile
    profile-macos      # Set profile to macOS
    profile-linux      # Set profile to Linux
    profile-mini       # Set profile to Mini
    validate           # Validate all profile templates
```

</details>

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **🐛 Report bugs** - Open an issue describing the problem
2. **💡 Suggest features** - Share your ideas for improvements
3. **📝 Improve docs** - Fix typos, clarify instructions
4. **🔧 Submit PRs** - Fix bugs or add features

### Development Workflow

```bash
# Fork and clone the repository
git clone https://github.com/yourusername/homeup.git
cd homeup

# Make your changes
chezmoi edit <file>

# Validate templates
just validate

# Test your changes
just diff
just apply

# Commit and push
git add .
git commit -m "feat: your amazing feature"
git push origin your-branch
```

---

## 📚 Documentation

<details>
<summary><b>🔗 Additional Resources</b></summary>

- [Chezmoi Documentation](https://www.chezmoi.io/) - Dotfile manager
- [Homebrew Documentation](https://docs.brew.sh/) - Package manager
- [Bootstrap Script Reference](./bootstrap.sh) - Detailed script documentation
- [Package Management](./packages/README.md) - Package organization
- [Refactor Plan](./REFACTOR_PLAN.md) - v2.0 architecture changes

</details>

---

## ⚠️ Breaking Changes (v2.0)

If you're upgrading from v1.x, please note:

- **Profile Renaming**: `workstation` → `macos`, `server` → `linux`, `codespace` → `mini`
- **Linux GUI Removed**: Linux profile is now strictly headless
- **Flatpak Removed**: No more GUI app management on Linux
- **Mini Profile**: Now standalone (doesn't inherit from core)

See [REFACTOR_PLAN.md](./REFACTOR_PLAN.md) for detailed migration guide.

---

## 📄 License

**MIT License** - See [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with ❤️ by [zopiya](https://github.com/zopiya)**

*If you find this helpful, consider giving it a ⭐ on GitHub!*

</div>