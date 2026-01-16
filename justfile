set shell := ["bash", "-uc"]
set dotenv-load := true

CHEZMOI_SOURCE := justfile_directory()
PROFILE := env_var_or_default("HOMEUP_PROFILE", if os() == "macos" { "macos" } else { "linux" })
BREW_PREFIX := if os() == "macos" { "/opt/homebrew" } else { "/home/linuxbrew/.linuxbrew" }

[private]
check-brew:
    @command -v brew >/dev/null 2>&1 || { echo "Error: Homebrew not found. Please install Homebrew first."; exit 1; }

@default:
    just --choose

@help:
    echo "Homeup Task Runner (v4.0)"
    echo ""
    echo "Quick Start (new machine):"
    echo "  just check            Verify prerequisites"
    echo "  just bootstrap        Complete install + setup"
    echo ""
    echo "Package Management:"
    echo "  just install          Install all packages"
    echo "  just install-bootstrap Install critical foundation tools"
    echo "  just install-core     Install core CLI tools"
    echo "  just install-profile  Install profile-specific tools"
    echo ""
    echo "Environment Setup:"
    echo "  just setup            Run all setup tasks"
    echo "  just setup-shell      Configure Zsh as default shell"
    echo "  just setup-runtimes   Configure Mise and runtimes"
    echo "  just setup-security   Configure GPG (macOS only)"
    echo "  just setup-tools      Configure FZF, Atuin, Sheldon"
    echo ""
    echo "Dotfiles (chezmoi):"
    echo "  just apply            Apply configuration"
    echo "  just diff             Show pending changes"
    echo "  just update           Pull and apply from remote"
    echo ""
    echo "Maintenance:"
    echo "  just doctor           Run health checks"
    echo "  just upgrade          Upgrade all packages"
    echo "  just clean            Clean caches"
    echo ""
    echo "Run 'just --list' for all tasks"

bootstrap: install setup
    @echo ""
    @echo "Bootstrap complete!"
    @echo "Please restart your shell: exec zsh -l"

# Install all packages (bootstrap → core → profile)
install: check-brew install-bootstrap install-core install-profile
    @echo "All packages installed"

# Install critical foundation tools (zsh, git, starship, etc.)
install-bootstrap: check-brew
    #!/usr/bin/env bash
    set -euo pipefail
    BREWFILE="{{CHEZMOI_SOURCE}}/packages/Brewfile.bootstrap"
    if [[ ! -f "$BREWFILE" ]]; then
        echo "Error: Brewfile.bootstrap not found at $BREWFILE"
        exit 1
    fi
    echo "Installing: Brewfile.bootstrap"
    brew bundle --file="$BREWFILE"
    echo "Bootstrap packages installed"

# Install core CLI tools
install-core: check-brew
    #!/usr/bin/env bash
    set -euo pipefail
    BREWFILE="{{CHEZMOI_SOURCE}}/packages/Brewfile.core"
    if [[ ! -f "$BREWFILE" ]]; then
        echo "Error: Brewfile.core not found at $BREWFILE"
        exit 1
    fi
    echo "Installing: Brewfile.core"
    brew bundle --file="$BREWFILE"
    echo "Core packages installed"

# Install profile-specific tools
install-profile: check-brew
    #!/usr/bin/env bash
    set -euo pipefail
    PROFILE="{{PROFILE}}"
    BREWFILE="{{CHEZMOI_SOURCE}}/packages/Brewfile.${PROFILE}"

    if [[ ! "$PROFILE" =~ ^(macos|linux)$ ]]; then
        echo "Error: Unknown profile: $PROFILE"
        exit 1
    fi

    if [[ ! -f "$BREWFILE" ]]; then
        echo "Error: Brewfile.${PROFILE} not found at $BREWFILE"
        exit 1
    fi

    echo "Installing: Brewfile.${PROFILE}"
    brew bundle --file="$BREWFILE"
    echo "Profile packages installed"

# Install without upgrading existing packages
install-no-upgrade: check-brew
    #!/usr/bin/env bash
    set -euo pipefail
    PROFILE="{{PROFILE}}"
    SOURCE="{{CHEZMOI_SOURCE}}/packages"

    echo "Installing packages (no upgrade)..."
    brew bundle --file="${SOURCE}/Brewfile.bootstrap" --no-upgrade
    brew bundle --file="${SOURCE}/Brewfile.core" --no-upgrade

    if [[ -f "${SOURCE}/Brewfile.${PROFILE}" ]]; then
        brew bundle --file="${SOURCE}/Brewfile.${PROFILE}" --no-upgrade
    else
        echo "Warning: Brewfile.${PROFILE} not found, skipping"
    fi
    echo "Packages installed (without upgrade)"

# Run all setup tasks
setup: setup-shell setup-runtimes setup-security setup-tools
    @echo "Setup complete"

# Configure Zsh as default shell
setup-shell:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Configuring shell..."

    # Skip in CI/container
    if [[ "${CI:-}" == "true" ]] || [[ -f /.dockerenv ]]; then
        echo "Skipping shell change in CI/container"
        exit 0
    fi

    # Find Zsh
    TARGET_SHELL=""
    if [[ -x "{{BREW_PREFIX}}/bin/zsh" ]]; then
        TARGET_SHELL="{{BREW_PREFIX}}/bin/zsh"
    elif command -v zsh >/dev/null 2>&1; then
        TARGET_SHELL="$(command -v zsh)"
    else
        echo "Warning: Zsh not found"
        exit 0
    fi

    echo "Found Zsh: $TARGET_SHELL"

    # Get current shell
    if [[ "$(uname)" == "Darwin" ]]; then
        CURRENT_SHELL=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}' || echo "$SHELL")
    else
        CURRENT_SHELL=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")
    fi

    if [[ "$CURRENT_SHELL" == "$TARGET_SHELL" ]]; then
        echo "Default shell is already Zsh"
        exit 0
    fi

    # Add to /etc/shells if needed
    if ! grep -qx "$TARGET_SHELL" /etc/shells 2>/dev/null; then
        echo "Adding $TARGET_SHELL to /etc/shells..."
        if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
            echo "$TARGET_SHELL" | sudo tee -a /etc/shells >/dev/null
        else
            echo "Warning: Cannot modify /etc/shells (no sudo)"
        fi
    fi

    # Change default shell
    echo "Changing default shell to Zsh..."
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        sudo chsh -s "$TARGET_SHELL" "$USER" 2>/dev/null || chsh -s "$TARGET_SHELL" 2>/dev/null || true
    else
        chsh -s "$TARGET_SHELL" 2>/dev/null || echo "Warning: Could not change shell (may need password)"
    fi
    echo "Shell configured"

# Configure Mise and global runtimes
setup-runtimes:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Configuring runtimes..."

    # Add mise to PATH
    export PATH="$HOME/.local/bin:$HOME/.mise/bin:$PATH"

    if ! command -v mise >/dev/null 2>&1; then
        echo "Warning: Mise not found (install with: just install-core)"
        exit 0
    fi

    # Trust and install
    mise trust --all 2>/dev/null || true
    mise install -y 2>/dev/null || true

    # Set global defaults if not configured
    if [[ ! -f "$HOME/.config/mise/config.toml" ]] && [[ ! -f "$HOME/.tool-versions" ]]; then
        echo "Setting global runtimes..."
        mise use -g python@3.12 node@lts -y 2>/dev/null || true
    fi

    echo "Runtimes configured"

# Configure GPG and security (macOS only)
setup-security:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Configuring security..."

    if [[ "{{PROFILE}}" != "macos" ]]; then
        echo "Skipping security setup (Linux profile)"
        exit 0
    fi

    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Skipping security setup (not macOS)"
        exit 0
    fi

    # GPG Agent
    if command -v gpgconf >/dev/null 2>&1; then
        echo "Reloading GPG Agent..."
        gpgconf --kill gpg-agent 2>/dev/null || true
        sleep 1
        gpgconf --launch gpg-agent 2>/dev/null || true
        echo "GPG Agent reloaded"
    fi

    # YubiKey check
    if command -v ykman >/dev/null 2>&1; then
        echo "YubiKey Manager available"
    fi

    echo "Security configured"

# Configure tools (FZF, Atuin, Sheldon, Starship)
setup-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Configuring tools..."

    # FZF key bindings
    FZF_INSTALL="{{BREW_PREFIX}}/opt/fzf/install"
    if [[ -f "$FZF_INSTALL" ]] && [[ ! -f "$HOME/.fzf.zsh" ]]; then
        echo "Installing FZF key bindings..."
        "$FZF_INSTALL" --all --no-bash --no-fish 2>/dev/null || true
    fi

    # Atuin
    if command -v atuin >/dev/null 2>&1; then
        if [[ ! -d "$HOME/.local/share/atuin" ]]; then
            echo "Initializing Atuin..."
            atuin init zsh >/dev/null 2>&1 || true
        fi
    fi

    # Sheldon
    if command -v sheldon >/dev/null 2>&1; then
        if [[ -f "$HOME/.config/sheldon/plugins.toml" ]]; then
            echo "Locking Sheldon plugins..."
            sheldon lock 2>/dev/null || true
        fi
    fi

    # Starship check
    if command -v starship >/dev/null 2>&1; then
        echo "Starship prompt available"
    fi

    echo "Tools configured"

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

# Show current profile
@profile:
    echo "Current Profile: {{PROFILE}}"
    echo ""
    echo "Available:"
    echo "  macos - Full macOS workstation (GPG, YubiKey, GUI)"
    echo "  linux - Servers, containers, Codespaces (SSH-only)"
    echo ""
    echo "Profile is auto-detected based on OS."
    echo "Override: export HOMEUP_PROFILE=<profile>"

# Run health checks
doctor: check-brew
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Homeup Health Check ==="
    echo ""
    errors=0

    # Check required tools
    echo "Required tools:"
    for cmd in brew chezmoi git just; do
        if command -v "$cmd" &>/dev/null; then
            echo "  [OK] $cmd"
        else
            echo "  [FAIL] $cmd"
            errors=$((errors + 1))
        fi
    done

    # Check optional tools
    echo ""
    echo "Optional tools:"
    for cmd in zsh starship sheldon mise shfmt shellcheck lefthook topgrade; do
        if command -v "$cmd" &>/dev/null; then
            echo "  [OK] $cmd"
        else
            echo "  [--] $cmd (not installed)"
        fi
    done

    # Check Brewfiles
    echo ""
    echo "Brewfiles:"
    for file in packages/Brewfile.{bootstrap,core,macos,linux}; do
        if [[ -f "$file" ]]; then
            echo "  [OK] $file"
        else
            echo "  [--] $file (not found)"
        fi
    done

    # Check profile
    echo ""
    echo "Profile: {{PROFILE}}"
    if [[ "{{PROFILE}}" =~ ^(macos|linux)$ ]]; then
        echo "  [OK] Valid profile"
    else
        echo "  [FAIL] Invalid profile"
        errors=$((errors + 1))
    fi

    echo ""
    if [[ $errors -eq 0 ]]; then
        echo "All checks passed"
    else
        echo "$errors error(s) found"
        exit 1
    fi

# Verify prerequisites before setup
check:
    #!/usr/bin/env bash
    set -euo pipefail

    PROFILE="{{PROFILE}}"

    echo "=== Homeup Environment Check ==="
    echo "Profile: $PROFILE"
    echo ""

    errors=0

    if command -v brew >/dev/null 2>&1; then
        echo "[OK] Homebrew: $(brew --prefix)"
    else
        echo "[FAIL] Homebrew not found"
        errors=$((errors + 1))
    fi

    if command -v just >/dev/null 2>&1; then
        echo "[OK] just found"
    else
        echo "[WARN] just not found (brew install just)"
    fi

    if command -v git >/dev/null 2>&1; then
        echo "[OK] git found"
    else
        echo "[FAIL] git not found"
        errors=$((errors + 1))
    fi

    if command -v ssh >/dev/null 2>&1; then
        ssh_version=$(ssh -V 2>&1 | grep -oE 'OpenSSH_[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+')
        if [[ -n "$ssh_version" ]]; then
            major=$(echo "$ssh_version" | cut -d. -f1)
            minor=$(echo "$ssh_version" | cut -d. -f2)
            if [[ $major -gt 8 ]] || [[ $major -eq 8 && $minor -ge 2 ]]; then
                echo "[OK] OpenSSH $ssh_version (FIDO supported)"
            else
                echo "[WARN] OpenSSH $ssh_version (FIDO requires 8.2+)"
            fi
        else
            echo "[WARN] OpenSSH version unknown"
        fi
    else
        echo "[FAIL] OpenSSH not found"
        errors=$((errors + 1))
    fi

    echo ""
    if [[ $errors -eq 0 ]]; then
        echo "Environment check passed"
        echo "Next: just bootstrap"
    else
        echo "$errors error(s) found"
        echo "Install Homebrew first:"
        echo ""
        echo "    /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

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
    echo "Caches cleaned"

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

# Run all CI checks
ci: check-brew
    @echo "=== Running CI Checks ==="
    @echo "[1/4] Linting..." && just lint
    @echo "[2/4] Validating packages..." && just pkg-validate
    @echo "[3/4] Checking duplicates..." && just pkg-duplicates
    @echo "[4/4] Health check..." && just doctor
    @echo ""
    @echo "All checks passed"

# Quick validation
@validate-all:
    just validate
    just pkg-duplicates

# Validate templates for all profiles
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Validating Templates ==="
    SOURCE="{{CHEZMOI_SOURCE}}"
    failed=0

    for profile in macos linux; do
        echo "Testing: $profile"
        BREWFILE="${SOURCE}/packages/Brewfile.${profile}"

        if [[ ! -f "$BREWFILE" ]]; then
            echo "  [FAIL] $profile (Brewfile not found)"
            failed=1
            continue
        fi

        if HOMEUP_PROFILE=$profile chezmoi init --source "$SOURCE" --destination "/tmp/chezmoi-test-$profile" --dry-run 2>/dev/null; then
            echo "  [OK] $profile"
            rm -rf "/tmp/chezmoi-test-$profile" 2>/dev/null || true
        else
            echo "  [FAIL] $profile (chezmoi init failed)"
            failed=1
        fi
    done

    [ $failed -eq 0 ] && echo "All profiles valid" || exit 1

# Validate package availability
pkg-validate: check-brew
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Package Validation ==="
    PACKAGES_DIR="{{CHEZMOI_SOURCE}}/packages"

    if [[ ! -d "$PACKAGES_DIR" ]]; then
        echo "Error: packages directory not found at $PACKAGES_DIR"
        exit 1
    fi

    failed=0

    for brewfile in Brewfile.{bootstrap,core,macos,linux}; do
        BREWFILE_PATH="${PACKAGES_DIR}/${brewfile}"
        [ ! -f "$BREWFILE_PATH" ] && continue
        echo "Checking $brewfile..."

        while read -r pkg; do
            [ -z "$pkg" ] && continue
            if brew info "$pkg" &>/dev/null; then
                echo "  [OK] $pkg"
            else
                echo "  [FAIL] $pkg (not found)"
                failed=1
            fi
        done < <(grep '^brew "' "$BREWFILE_PATH" 2>/dev/null | sed 's/^brew "\([^"]*\)".*/\1/' || true)

        while read -r pkg; do
            [ -z "$pkg" ] && continue
            if brew info --cask "$pkg" &>/dev/null; then
                echo "  [OK] [cask] $pkg"
            else
                echo "  [FAIL] [cask] $pkg (not found)"
                failed=1
            fi
        done < <(grep '^cask "' "$BREWFILE_PATH" 2>/dev/null | sed 's/^cask "\([^"]*\)".*/\1/' || true)
    done

    [ $failed -eq 0 ] && echo "All packages valid" || { echo "Some packages not found"; exit 1; }

# Check for duplicate packages
pkg-duplicates: check-brew
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Checking Duplicates ==="
    PACKAGES_DIR="{{CHEZMOI_SOURCE}}/packages"

    if [[ ! -d "$PACKAGES_DIR" ]]; then
        echo "Error: packages directory not found at $PACKAGES_DIR"
        exit 1
    fi

    has_dupes=0

    # Bootstrap vs Core
    dupes=$(comm -12 \
        <(grep -E '^brew "' "${PACKAGES_DIR}/Brewfile.bootstrap" 2>/dev/null | sed 's/^brew "\([^"]*\)".*/\1/' | sort) \
        <(grep -E '^brew "' "${PACKAGES_DIR}/Brewfile.core" 2>/dev/null | sed 's/^brew "\([^"]*\)".*/\1/' | sort) 2>/dev/null || true)
    if [ -n "$dupes" ]; then
        echo "Bootstrap <-> Core:"
        echo "$dupes" | sed 's/^/  [DUP] /'
        has_dupes=1
    else
        echo "Bootstrap <-> Core: OK"
    fi

    # Core vs macOS
    dupes=$(comm -12 \
        <(grep -E '^brew "' "${PACKAGES_DIR}/Brewfile.core" 2>/dev/null | sed 's/^brew "\([^"]*\)".*/\1/' | sort) \
        <(grep -E '^brew "' "${PACKAGES_DIR}/Brewfile.macos" 2>/dev/null | sed 's/^brew "\([^"]*\)".*/\1/' | sort) 2>/dev/null || true)
    if [ -n "$dupes" ]; then
        echo "Core <-> macOS:"
        echo "$dupes" | sed 's/^/  [DUP] /'
        has_dupes=1
    else
        echo "Core <-> macOS: OK"
    fi

    # Core vs Linux
    dupes=$(comm -12 \
        <(grep -E '^brew "' "${PACKAGES_DIR}/Brewfile.core" 2>/dev/null | sed 's/^brew "\([^"]*\)".*/\1/' | sort) \
        <(grep -E '^brew "' "${PACKAGES_DIR}/Brewfile.linux" 2>/dev/null | sed 's/^brew "\([^"]*\)".*/\1/' | sort) 2>/dev/null || true)
    if [ -n "$dupes" ]; then
        echo "Core <-> Linux:"
        echo "$dupes" | sed 's/^/  [DUP] /'
        has_dupes=1
    else
        echo "Core <-> Linux: OK"
    fi

    [ $has_dupes -eq 0 ] && echo "No duplicates found" || { echo "Duplicates found"; exit 1; }

# Install git hooks
@install-hooks:
    if command -v lefthook &>/dev/null; then \
        lefthook install; \
    else \
        echo "Warning: lefthook not installed (brew install lefthook)"; \
    fi

# Format shell scripts
@fmt:
    if command -v shfmt &>/dev/null; then \
        find . -name "*.sh" -type f ! -path "./.git/*" -exec shfmt -w -i 4 {} \;; \
        echo "Formatted"; \
    else \
        echo "Warning: shfmt not installed"; \
    fi

# Lint shell scripts
@lint:
    if command -v shellcheck &>/dev/null; then \
        find . -name "*.sh" -type f ! -path "./.git/*" -exec shellcheck {} \;; \
    else \
        echo "Warning: shellcheck not installed"; \
    fi

# Quick commit
commit msg:
    @git add -A
    @git commit -m "{{msg}}"

# Initialize new machine
[confirm("Initialize homeup on this machine?")]
init:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v brew >/dev/null 2>&1 || { echo "Error: Homebrew not found"; exit 1; }
    command -v chezmoi >/dev/null 2>&1 || { echo "Error: chezmoi not found (brew install chezmoi)"; exit 1; }
    echo "Initializing via chezmoi (Profile: {{PROFILE}})"
    HOMEUP_PROFILE={{PROFILE}} chezmoi init --source . --apply
    echo "Configuration applied"
    echo ""
    echo "Next step: just bootstrap"

# Reset chezmoi state
[confirm("This will purge all chezmoi state. Continue?")]
reset:
    @chezmoi purge --force
    @echo "State cleared"

# Re-initialize environment (Reset + Init)
[confirm("This will purge state and re-initialize. Continue?")]
reinit:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v brew >/dev/null 2>&1 || { echo "Error: Homebrew not found"; exit 1; }
    command -v chezmoi >/dev/null 2>&1 || { echo "Error: chezmoi not found"; exit 1; }
    echo "1. Resetting state..."
    chezmoi purge --force
    echo "2. Re-initializing via chezmoi (Profile: {{PROFILE}})"
    HOMEUP_PROFILE={{PROFILE}} chezmoi init --source . --apply
    echo "Re-initialization complete"
    echo ""
    echo "Next step: just bootstrap"
