# ==============================================================================
# Homeup Justfile - Dotfiles Management Task Runner
# ==============================================================================
# Version: 3.0
# Usage: just <task>
# ==============================================================================

set shell := ["bash", "-uc"]
set dotenv-load := true

# Variables
CHEZMOI_SOURCE := justfile_directory()
PROFILE := env_var_or_default("HOMEUP_PROFILE", "mini")

# ------------------------------------------------------------------------------
# Help & Defaults
# ------------------------------------------------------------------------------

# Show interactive menu (default)
@default:
    just --choose

# Show help information
@help:
    echo "Homeup Task Runner"
    echo ""
    echo "Common Tasks:"
    echo "  apply               Apply dotfiles"
    echo "  diff                Show changes"
    echo "  update              Pull and apply from remote"
    echo "  install             Install packages for current profile"
    echo ""
    echo "Maintenance:"
    echo "  doctor              Run health checks"
    echo "  clean               Clean caches"
    echo "  upgrade             Upgrade all packages (via topgrade)"
    echo ""
    echo "Development:"
    echo "  ci                  Run all CI checks"
    echo "  lint                Run shellcheck"
    echo "  validate            Validate templates"
    echo ""
    echo "Run 'just --list' for all tasks"

# ------------------------------------------------------------------------------
# Core Operations
# ------------------------------------------------------------------------------

# Apply dotfiles configuration
@apply:
    chezmoi apply

# Apply with verbose output
@apply-verbose:
    chezmoi apply -v

# Show diff before applying
@diff:
    chezmoi diff

# Interactive apply
@apply-interactive:
    chezmoi apply --interactive

# Update from remote and apply
@update:
    chezmoi update

# Show chezmoi status
@status:
    chezmoi status

# Edit a managed file
edit file:
    chezmoi edit {{file}}

# Add file to chezmoi
add file:
    @echo "Adding {{file}}..."
    chezmoi add {{file}}

# ------------------------------------------------------------------------------
# Package Management
# ------------------------------------------------------------------------------

# Install packages for current profile
install:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing packages (Profile: {{PROFILE}})"

    case "{{PROFILE}}" in
        mini)
            brew bundle --file=packages/Brewfile.mini
            ;;
        macos)
            brew bundle --file=packages/Brewfile.core
            brew bundle --file=packages/Brewfile.macos
            ;;
        linux)
            brew bundle --file=packages/Brewfile.core
            brew bundle --file=packages/Brewfile.linux
            ;;
        *)
            echo "Unknown profile: {{PROFILE}}"
            exit 1
            ;;
    esac
    echo "✓ Installation complete"

# Install packages without upgrading existing ones
install-no-upgrade:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{PROFILE}}" in
        mini) brew bundle --file=packages/Brewfile.mini --no-upgrade ;;
        macos)
            brew bundle --file=packages/Brewfile.core --no-upgrade
            brew bundle --file=packages/Brewfile.macos --no-upgrade
            ;;
        linux)
            brew bundle --file=packages/Brewfile.core --no-upgrade
            brew bundle --file=packages/Brewfile.linux --no-upgrade
            ;;
    esac

# List installed packages
@list:
    brew list --formula
    @[ "$(uname)" = "Darwin" ] && (echo ""; echo "Casks:"; brew list --cask) || true

# Check outdated packages
@outdated:
    brew outdated

# Clean up unused packages
@cleanup:
    brew cleanup --prune=all
    brew autoremove

# ------------------------------------------------------------------------------
# Profile Management
# ------------------------------------------------------------------------------

# Show current profile
@profile:
    echo "Current Profile: {{PROFILE}}"
    echo ""
    echo "Available:"
    echo "  macos - Full macOS workstation (GPG, YubiKey, GUI)"
    echo "  linux - Headless Linux server (SSH-only)"
    echo "  mini  - Minimal environment (containers, codespaces)"
    echo ""
    echo "Switch: export HOMEUP_PROFILE=<profile>"

# ------------------------------------------------------------------------------
# Diagnostics & Maintenance
# ------------------------------------------------------------------------------

# Run health checks
doctor:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Homeup Health Check ==="
    echo ""
    errors=0

    # Check tools
    echo "Checking tools..."
    for cmd in brew chezmoi git; do
        command -v "$cmd" &>/dev/null && echo "  ✓ $cmd" || { echo "  ✗ $cmd"; errors=$((errors + 1)); }
    done

    # Check optional tools
    for cmd in shfmt shellcheck lefthook topgrade; do
        command -v "$cmd" &>/dev/null && echo "  ✓ $cmd" || echo "  ○ $cmd (optional)"
    done

    # Check files
    echo ""
    echo "Checking files..."
    for file in bootstrap.sh packages/Brewfile.core; do
        [ -f "$file" ] && echo "  ✓ $file" || { echo "  ✗ $file"; errors=$((errors + 1)); }
    done

    # Check profile
    echo ""
    echo "Checking profile..."
    echo "  Profile: {{PROFILE}}"
    [[ "{{PROFILE}}" =~ ^(macos|linux|mini)$ ]] && echo "  ✓ Valid" || { echo "  ✗ Invalid"; errors=$((errors + 1)); }

    echo ""
    [ $errors -eq 0 ] && echo "✓ All checks passed" || { echo "✗ $errors error(s) found"; exit 1; }

# Upgrade all packages (via topgrade)
@upgrade:
    if command -v topgrade &>/dev/null; then \
        topgrade; \
    else \
        echo "Topgrade not found, using brew..."; \
        brew update && brew upgrade && brew cleanup; \
    fi

# Clean caches
@clean:
    chezmoi purge --force || true
    rm -rf /tmp/chezmoi-test-* 2>/dev/null || true
    echo "✓ Caches cleaned"

# Deep clean (includes Homebrew)
@clean-all:
    just clean
    just cleanup

# Emergency fix helper
rescue:
    @echo "=== Emergency Rescue ==="
    @echo "1. Purging chezmoi cache..."
    @chezmoi purge --force || true
    @echo "2. Reinstalling git hooks..."
    @just install-hooks || true
    @echo "3. Running health check..."
    @just doctor

# ------------------------------------------------------------------------------
# Testing & CI
# ------------------------------------------------------------------------------

# Run all CI checks
ci:
    @echo "=== Running CI Checks ==="
    @echo "[1/4] Linting..." && just lint
    @echo "[2/4] Validating packages..." && just pkg-validate
    @echo "[3/4] Checking duplicates..." && just pkg-duplicates
    @echo "[4/4] Health check..." && just doctor
    @echo ""
    @echo "✓ All checks passed"

# Quick validation
@check:
    just validate
    just pkg-duplicates

# Validate templates for all profiles
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Validating Templates ==="
    failed=0
    for profile in macos linux mini; do
        echo "Testing: $profile"
        export HOMEUP_PROFILE=$profile
        if chezmoi init --source . --destination /tmp/chezmoi-test-$profile --dry-run 2>/dev/null; then
            echo "  ✓ $profile"
        else
            echo "  ✗ $profile"
            failed=1
        fi
    done
    [ $failed -eq 0 ] && echo "✓ All profiles valid" || exit 1

# Validate package availability
pkg-validate:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Package Validation ==="
    cd packages
    failed=0

    for brewfile in Brewfile.{core,macos,linux,mini}; do
        [ ! -f "$brewfile" ] && continue
        echo "Checking $brewfile..."

        # Check formulae
        while read -r pkg; do
            [ -z "$pkg" ] && continue
            if brew info "$pkg" &>/dev/null; then
                echo "  ✓ $pkg"
            else
                echo "  ✗ $pkg (not found in brew)"
                # Try to get more info for debugging
                brew search "$pkg" 2>/dev/null | head -3 | sed 's/^/      /' || true
                failed=1
            fi
        done < <(grep '^brew "' "$brewfile" 2>/dev/null | sed 's/^brew "\([^"]*\)".*/\1/' || true)

        # Check casks
        while read -r pkg; do
            [ -z "$pkg" ] && continue
            if brew info --cask "$pkg" &>/dev/null; then
                echo "  ✓ [cask] $pkg"
            else
                echo "  ✗ [cask] $pkg (not found in brew)"
                failed=1
            fi
        done < <(grep '^cask "' "$brewfile" 2>/dev/null | sed 's/^cask "\([^"]*\)".*/\1/' || true)
    done

    [ $failed -eq 0 ] && echo "✓ All packages valid" || { echo "✗ Some packages not found"; exit 1; }

# Check for duplicate packages
pkg-duplicates:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Checking Duplicates ==="
    cd packages

    has_dupes=0

    # Core vs macOS
    dupes=$(comm -12 \
        <(grep -E '^brew "' Brewfile.core | sed 's/^brew "\([^"]*\)".*/\1/' | sort) \
        <(grep -E '^brew "' Brewfile.macos | sed 's/^brew "\([^"]*\)".*/\1/' | sort) 2>/dev/null || true)
    if [ -n "$dupes" ]; then
        echo "Core ↔ macOS:"
        echo "$dupes" | sed 's/^/  ✗ /'
        has_dupes=1
    else
        echo "Core ↔ macOS: ✓"
    fi

    # Core vs Linux
    dupes=$(comm -12 \
        <(grep -E '^brew "' Brewfile.core | sed 's/^brew "\([^"]*\)".*/\1/' | sort) \
        <(grep -E '^brew "' Brewfile.linux | sed 's/^brew "\([^"]*\)".*/\1/' | sort) 2>/dev/null || true)
    if [ -n "$dupes" ]; then
        echo "Core ↔ Linux:"
        echo "$dupes" | sed 's/^/  ✗ /'
        has_dupes=1
    else
        echo "Core ↔ Linux: ✓"
    fi

    [ $has_dupes -eq 0 ] && echo "✓ No duplicates found" || { echo "✗ Duplicates found"; exit 1; }

# ------------------------------------------------------------------------------
# Development
# ------------------------------------------------------------------------------

# Install git hooks
@install-hooks:
    if command -v lefthook &>/dev/null; then \
        lefthook install; \
    else \
        echo "⚠ lefthook not installed (brew install lefthook)"; \
    fi

# Format shell scripts
@fmt:
    if command -v shfmt &>/dev/null; then \
        find . -name "*.sh" -type f ! -path "./.git/*" -exec shfmt -w -i 4 {} \;; \
        echo "✓ Formatted"; \
    else \
        echo "⚠ shfmt not installed"; \
    fi

# Lint shell scripts
@lint:
    if command -v shellcheck &>/dev/null; then \
        find . -name "*.sh" -type f ! -path "./.git/*" -exec shellcheck {} \;; \
    else \
        echo "⚠ shellcheck not installed"; \
    fi

# Quick commit
commit msg:
    @git add -A
    @git commit -m "{{msg}}"

# Initialize new machine
[confirm("Initialize homeup on this machine?")]
init:
    ./bootstrap.sh -p {{PROFILE}}
    @echo "✓ Initialization complete"

# Reset chezmoi state
[confirm("⚠ This will purge all chezmoi state. Continue?")]
reset:
    @chezmoi purge --force
    @echo "✓ State cleared"
