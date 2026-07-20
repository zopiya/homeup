set shell := ["bash", "-uc"]
set dotenv-load := true

CHEZMOI_SOURCE := justfile_directory()

default:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "homeup-linux"
    echo ""
    echo "Usage: just [recipe]"
    echo ""
    echo "Server provisioning (Day 0, run once as root on a fresh server)"
    echo "  provision            Create user, harden SSH, configure firewall/hostname/timezone"
    echo ""
    echo "New machine (Day 1, run as your user)"
    echo "  bootstrap            Full setup: install -> setup -> apply"
    echo "  install              Install apt packages + upstream tool installers"
    echo ""
    echo "Dotfiles"
    echo "  apply                Apply dotfile changes"
    echo "  diff                 Preview pending changes"
    echo "  update               Pull latest and apply"
    echo ""
    echo "Maintenance"
    echo "  doctor               Health check for required/optional tools"
    echo "  upgrade              Upgrade all packages"
    echo "  clean                Clean caches"
    echo ""
    echo "Development"
    echo "  validate             Validate chezmoi templates"
    echo "  lint                 Shellcheck all shell files"
    echo "  fmt                  Shfmt format all shell files"
    echo ""
    echo "Run 'just [recipe]' to execute a specific recipe"

# Alias for help
@help:
    just

[private]
check-apt:
    @command -v apt-get >/dev/null 2>&1 || { echo "Error: apt-get not found. This repo targets Debian/Ubuntu."; exit 1; }

# ── Server provisioning (Day 0) ─────────────────────────────────────────────

# Create user, harden SSH, configure firewall/hostname/timezone (run once, as root)
@provision:
    sudo bash "{{CHEZMOI_SOURCE}}/packages/server-init.sh"

# ── New machine (Day 1) ──────────────────────────────────────────────────────

# Complete setup: install packages → configure environment → apply dotfiles
bootstrap: install setup apply
    @echo ""
    @echo "Bootstrap complete! Restart your shell: exec zsh -l"

# ── Packages ───────────────────────────────────────────────────────────────────

# Install apt packages + upstream tool installers
install: check-apt _install-apt _install-tools
    @echo "All packages installed"

[private]
_install-apt: check-apt
    sudo apt-get update -qq
    xargs -a "{{CHEZMOI_SOURCE}}/packages/apt-packages.txt" sudo apt-get install -y

[private]
_install-tools:
    bash "{{CHEZMOI_SOURCE}}/packages/install-tools.sh"

# ── Environment ────────────────────────────────────────────────────────────────

# Configure shell and tools
setup: _setup-shell _setup-tools
    @echo "Setup complete"

[private]
_setup-shell:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "${CI:-}" == "true" ]] || [[ -f /.dockerenv ]]; then
      echo "⚠ Skipping shell change in CI/container"
      exit 0
    fi

    TARGET_SHELL="$(command -v zsh || true)"
    if [[ -z "$TARGET_SHELL" ]]; then
        echo "Warning: Zsh not found"; exit 0
    fi

    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
    [[ -z "$CURRENT_SHELL" ]] && CURRENT_SHELL="$SHELL"

    [[ "$CURRENT_SHELL" == "$TARGET_SHELL" ]] && { echo "Default shell already Zsh"; exit 0; } || true

    if [[ -z "$USER" ]]; then
        echo "Error: USER env not set"
        exit 1
    fi
    if [[ ! "$USER" =~ ^[a-z_][a-z0-9_]*$ ]]; then
        echo "Error: USER contains invalid characters: $USER"
        exit 1
    fi
    sudo chsh -s "$TARGET_SHELL" -- "$USER" 2>/dev/null || chsh -s "$TARGET_SHELL" -- "$USER" 2>/dev/null || true
    echo "Shell set to $TARGET_SHELL"

[private]
_setup-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v sheldon >/dev/null 2>&1 && [[ -f "$HOME/.config/sheldon/plugins.toml" ]]; then
        sheldon lock 2>/dev/null || true
        echo "Sheldon plugins locked"
    fi
    if command -v gpgconf >/dev/null 2>&1; then
        gpgconf --kill gpg-agent 2>/dev/null || true
        gpgconf --launch gpg-agent 2>/dev/null || true
    fi
    echo "Tools configured"

# ── Dotfiles ───────────────────────────────────────────────────────────────────

# Apply dotfiles
@apply:
    chezmoi apply

# Show pending dotfile changes
@diff:
    chezmoi diff

# Pull latest changes and apply
@update:
    chezmoi update

# ── Maintenance ────────────────────────────────────────────────────────────────

# Health check
doctor: check-apt
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== homeup-linux Health Check ==="
    echo ""
    errors=0

    echo "Required:"
    for cmd in chezmoi git just zsh; do
        if command -v "$cmd" &>/dev/null; then
            echo "  [OK] $cmd"
        else
            echo "  [FAIL] $cmd"
            errors=$((errors + 1))
        fi
    done

    echo ""
    echo "Optional:"
    for cmd in starship sheldon atuin direnv fzf shfmt shellcheck lazygit gh uv bat delta gitleaks age zellij zoxide nvim eza fastfetch glances lnav yq btm xh watchexec mtr rclone; do
        if command -v "$cmd" &>/dev/null; then
            echo "  [OK] $cmd"
        else
            echo "  [--] $cmd"
        fi
    done

    echo ""
    if [[ $errors -eq 0 ]]; then echo "All checks passed"
    else echo "$errors error(s) found"; exit 1; fi

# Upgrade all packages
@upgrade:
    sudo apt-get update && sudo apt-get upgrade -y

# Clean package caches
@clean:
    sudo apt-get autoremove -y 2>/dev/null || true
    sudo apt-get clean 2>/dev/null || true
    rm -rf /tmp/chezmoi-test-* 2>/dev/null || true
    echo "Caches cleaned"

# ── Development ────────────────────────────────────────────────────────────────

# Validate chezmoi templates
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Validating Templates ==="
    if chezmoi init --source "{{CHEZMOI_SOURCE}}" --destination "/tmp/chezmoi-test-linux" --dry-run 2>/dev/null; then
        echo "  [OK] linux"
    else
        echo "  [FAIL] linux"
        rm -rf "/tmp/chezmoi-test-linux" 2>/dev/null || true
        exit 1
    fi
    rm -rf "/tmp/chezmoi-test-linux" 2>/dev/null || true
    echo "Templates valid"

# Lint shell scripts with shellcheck (*.sh) and zsh syntax check (*.zsh)
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v shellcheck &>/dev/null; then
        find . -name "*.sh" -type f ! -path "./.git/*" -exec shellcheck {} \;
    else
        echo "Warning: shellcheck not installed"
    fi
    # shellcheck/shfmt don't support zsh; `zsh -n` is the closest available syntax check
    failed=0
    while IFS= read -r -d '' file; do
        zsh -n "$file" || failed=1
    done < <(find . -name "*.zsh" -type f ! -path "./.git/*" -print0)
    [[ $failed -eq 0 ]] && echo "zsh syntax OK" || exit 1

# Format shell scripts with shfmt
@fmt:
    if command -v shfmt &>/dev/null; then \
        find . -name "*.sh" -type f ! -path "./.git/*" -exec shfmt -w -i 4 {} \;; \
        echo "Formatted"; \
    else \
        echo "Warning: shfmt not installed"; \
    fi
