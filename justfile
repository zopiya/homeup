set shell := ["bash", "-uc"]
set dotenv-load := true

mod scripts 'scripts/justfile'

CHEZMOI_SOURCE := justfile_directory()

default:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
        bold=$'\033[1m'; reset=$'\033[0m'
    else
        bold=''; reset=''
    fi
    echo "${bold}homeup-linux${reset}"
    echo ""
    echo "Usage: just [recipe]"
    echo ""
    echo "${bold}Server provisioning${reset} (Day 0, run once as root on a fresh server)"
    echo "  provision            Create user, configure firewall/hostname/timezone"
    echo "                       (SSH hardening is separate and manual — see below)"
    echo ""
    echo "${bold}New machine${reset} (Day 1, run as your user)"
    echo "  bootstrap            Full setup: install -> setup -> apply"
    echo "  install              Install apt packages + upstream tool installers"
    echo ""
    echo "${bold}Dotfiles${reset}"
    echo "  apply                Apply dotfile changes"
    echo "  diff                 Preview pending changes"
    echo "  update               Pull latest and apply"
    echo ""
    echo "${bold}Maintenance${reset}"
    echo "  doctor               Health check for required/optional tools"
    echo "  upgrade              Upgrade all packages"
    echo "  clean                Clean caches"
    echo ""
    echo "${bold}Development${reset}"
    echo "  validate             Validate chezmoi templates"
    echo "  lint                 Shellcheck all shell files"
    echo "  fmt                  Shfmt format all shell files"
    echo ""
    echo "Run 'just [recipe]' to execute a specific recipe"
    echo "Run 'just --list' to see every recipe, including the individual"
    echo "scripts::* ones this menu doesn't list one by one (e.g. the manual,"
    echo "never-automatic 'just scripts::ssh-harden')"

# Alias for help
@help:
    just

[private]
check-apt:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then red=$'\033[31m'; reset=$'\033[0m'; else red=''; reset=''; fi
    command -v apt-get >/dev/null 2>&1 || {
        echo "${red}✗${reset} apt-get not found. This repo targets Debian/Ubuntu." >&2
        exit 1
    }

# ── Server provisioning (Day 0) ─────────────────────────────────────────────

# Create user, configure firewall/hostname/timezone (SSH hardening is separate — see scripts::ssh-harden)
provision: scripts::create-user scripts::ufw scripts::hostname scripts::timezone
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then green=$'\033[32m'; yellow=$'\033[33m'; reset=$'\033[0m'; else green=''; yellow=''; reset=''; fi
    echo ""
    echo "${green}✓ provision complete.${reset} Verify you can log in as the new user, then run:"
    echo "  ${yellow}just scripts::ssh-harden${reset}"

# ── New machine (Day 1) ──────────────────────────────────────────────────────

# Complete setup: install packages → configure environment → apply dotfiles
bootstrap: install setup apply
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then green=$'\033[32m'; reset=$'\033[0m'; else green=''; reset=''; fi
    echo ""
    echo "${green}✓ Bootstrap complete!${reset} Restart your shell: exec zsh -l"

# ── Packages ───────────────────────────────────────────────────────────────────

# Install apt packages + upstream tool installers
install: check-apt scripts::apt scripts::tools
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then green=$'\033[32m'; reset=$'\033[0m'; else green=''; reset=''; fi
    echo "${green}✓${reset} All packages installed"

# ── Environment ────────────────────────────────────────────────────────────────

# Configure shell (sheldon lock/gpg-agent reload now run via chezmoi apply hooks, not here)
setup: _setup-shell
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then green=$'\033[32m'; reset=$'\033[0m'; else green=''; reset=''; fi
    echo "${green}✓${reset} Setup complete"

[private]
_setup-shell:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then yellow=$'\033[33m'; reset=$'\033[0m'; else yellow=''; reset=''; fi
    if [[ "${CI:-}" == "true" ]] || [[ -f /.dockerenv ]]; then
      echo "${yellow}⚠${reset} Skipping shell change in CI/container"
      exit 0
    fi

    TARGET_SHELL="$(command -v zsh || true)"
    if [[ -z "$TARGET_SHELL" ]]; then
        echo "${yellow}⚠${reset} Zsh not found"; exit 0
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

# ── Dotfiles ───────────────────────────────────────────────────────────────────

# Apply dotfiles
@apply:
    echo "→ Applying dotfiles..."
    chezmoi init --source "{{CHEZMOI_SOURCE}}" --apply

# Show pending dotfile changes
@diff:
    echo "→ Diffing pending dotfile changes..."
    chezmoi diff

# Pull latest changes and apply
@update:
    echo "→ Pulling latest changes and applying..."
    chezmoi update

# ── Maintenance ────────────────────────────────────────────────────────────────

# Health check
doctor: check-apt
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
        green=$'\033[32m'; red=$'\033[31m'; dim=$'\033[2m'; reset=$'\033[0m'
    else
        green=''; red=''; dim=''; reset=''
    fi
    echo "=== homeup-linux Health Check ==="
    echo ""
    errors=0

    echo "Required:"
    for cmd in chezmoi git just zsh; do
        if command -v "$cmd" &>/dev/null; then
            echo "  ${green}[OK]${reset} $cmd"
        else
            echo "  ${red}[FAIL]${reset} $cmd"
            errors=$((errors + 1))
        fi
    done

    echo ""
    echo "Optional:"
    for cmd in starship sheldon atuin direnv fzf shfmt shellcheck lazygit gh uv bat delta gitleaks age zellij zoxide nvim eza fastfetch glances lnav yq btm xh watchexec mtr rclone; do
        if command -v "$cmd" &>/dev/null; then
            echo "  ${green}[OK]${reset} $cmd"
        else
            echo "  ${dim}[--] $cmd${reset}"
        fi
    done

    echo ""
    if [[ $errors -eq 0 ]]; then echo "${green}✓ All checks passed${reset}"
    else echo "${red}✗ $errors error(s) found${reset}"; exit 1; fi

# Upgrade all packages
@upgrade:
    echo "→ Upgrading all packages..."
    sudo apt-get update && sudo apt-get upgrade -y
    echo "✓ Packages upgraded"

# Clean package caches
@clean:
    sudo apt-get autoremove -y 2>/dev/null || true
    sudo apt-get clean 2>/dev/null || true
    rm -rf /tmp/chezmoi-test-* 2>/dev/null || true
    echo "✓ Caches cleaned"

# ── Development ────────────────────────────────────────────────────────────────

# Validate chezmoi templates
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then green=$'\033[32m'; red=$'\033[31m'; reset=$'\033[0m'; else green=''; red=''; reset=''; fi
    echo "=== Validating Templates ==="
    if chezmoi init --source "{{CHEZMOI_SOURCE}}" --destination "/tmp/chezmoi-test-linux" --dry-run 2>/dev/null; then
        echo "  ${green}[OK]${reset} linux"
    else
        echo "  ${red}[FAIL]${reset} linux"
        rm -rf "/tmp/chezmoi-test-linux" 2>/dev/null || true
        exit 1
    fi
    rm -rf "/tmp/chezmoi-test-linux" 2>/dev/null || true
    echo "${green}✓ Templates valid${reset}"

# Lint shell scripts with shellcheck (*.sh) and zsh syntax check (*.zsh)
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then green=$'\033[32m'; yellow=$'\033[33m'; reset=$'\033[0m'; else green=''; yellow=''; reset=''; fi
    if command -v shellcheck &>/dev/null; then
        find . -name "*.sh" -type f ! -path "./.git/*" -exec shellcheck {} \;
    else
        echo "${yellow}⚠ shellcheck not installed${reset}"
    fi
    # shellcheck/shfmt don't support zsh; `zsh -n` is the closest available syntax check
    failed=0
    while IFS= read -r -d '' file; do
        zsh -n "$file" || failed=1
    done < <(find . -name "*.zsh" -type f ! -path "./.git/*" -print0)
    [[ $failed -eq 0 ]] && echo "${green}✓ zsh syntax OK${reset}" || exit 1

# Format shell scripts with shfmt
@fmt:
    if command -v shfmt &>/dev/null; then \
        find . -name "*.sh" -type f ! -path "./.git/*" -exec shfmt -w -i 4 {} \;; \
        echo "✓ Formatted"; \
    else \
        echo "⚠ shfmt not installed"; \
    fi
