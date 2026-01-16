# Homeup

A streamlined dotfiles repository using chezmoi. Profile auto-detection based on OS (macOS or Linux).

## Quick Start

```bash
# 1. Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install minimal dependencies
brew install chezmoi just

# 3. Clone and apply configuration
git clone https://github.com/zopiya/homeup.git
cd homeup
chezmoi init --source . --apply

# 4. Complete installation and setup
just bootstrap
```

## Architecture

**Separation of Concerns:**

- **chezmoi** - Configuration file management (templates, sync)
- **justfile** - Task execution (packages, setup, maintenance)

```
chezmoi init --apply     → Sync configuration files (~/.zshrc, ~/.config/*, etc.)
just bootstrap           → Install packages + configure environment
```

## Profiles

| Profile | Detection | Use Case |
|---------|-----------|----------|
| **macos** | `.chezmoi.os == "darwin"` | Personal workstation (GUI, GPG, YubiKey) |
| **linux** | `.chezmoi.os == "linux"` | Servers, containers, Codespaces (headless) |

Profile is auto-detected. Override: `export HOMEUP_PROFILE=linux`

## Common Commands

### Quick Start

```bash
just bootstrap          # Complete install + setup (new machine)
```

### Package Management

```bash
just install            # Install all packages
just install-bootstrap  # Install critical foundation tools
just install-core       # Install core CLI tools
just install-profile    # Install profile-specific tools
just install-no-upgrade # Install without upgrading existing
```

### Environment Setup

```bash
just setup              # Run all setup tasks
just setup-shell        # Configure Zsh as default shell
just setup-runtimes     # Configure Mise and runtimes
just setup-security     # Configure GPG (macOS only)
just setup-tools        # Configure FZF, Atuin, Sheldon
```

### Dotfiles

```bash
just apply              # Apply configuration
just diff               # Show pending changes
just update             # Pull and apply from remote
```

### Maintenance

```bash
just doctor             # Run health checks
just upgrade            # Upgrade all packages
just clean              # Clean caches
```

## Project Structure

```
homeup/
├── justfile                    # Task runner (v4.0)
├── packages/
│   ├── Brewfile.bootstrap      # Critical foundation tools
│   ├── Brewfile.core           # Core CLI tools
│   ├── Brewfile.macos          # macOS-specific (GUI, security)
│   └── Brewfile.linux          # Linux-specific (headless)
├── .chezmoiscripts/
│   └── run_once_before_check.sh.tmpl  # Environment check
├── dot_config/                 # Public configuration
├── private_dot_ssh/            # SSH configuration
└── docs/                       # Documentation
```

## Requirements

- **Homebrew** - Must be installed before running
- **chezmoi** - Installed via `brew install chezmoi`
- **just** - Installed via `brew install just`

## License

MIT License
