#!/usr/bin/env bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Homeup Bootstrap Script
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# Purpose: Layer 0 Bootstrap - Environment Detection + Base Tools
# Version: 4.0.0
# License: MIT
#
# Scope (strictly limited):
#   1. Detect OS / Arch / Distro / Mode
#   2. Install system dependencies (Linux only)
#   3. Install Homebrew
#   4. Install Flatpak (Linux workstation only)
#   5. Install chezmoi via Homebrew
#   6. Optionally execute chezmoi init --apply (if DOTFILES_REPO is set)
#
# Output Variables:
#   HOMEUP_OS      - darwin | linux
#   HOMEUP_ARCH    - x86_64 | arm64
#   HOMEUP_DISTRO  - debian | fedora | arch | alpine | macos
#   HOMEUP_MODE    - workstation | server
#
# Optional automation:
#   Set DOTFILES_REPO environment variable to auto-initialize dotfiles:
#   DOTFILES_REPO=https://github.com/user/dotfiles ./bootstrap.sh
#
# This is a bootstrap script, NOT a configuration script.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -Eeuo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Constants
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly SCRIPT_VERSION="4.0.0"
readonly BREW_SHELLENV_FILE="$HOME/.config/homebrew/shellenv"
readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly SPINNER_FRAMES='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

# TTY detection for colors
if [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
    readonly IS_TTY=true
    readonly C_RESET=$'\033[0m'
    readonly C_GREEN=$'\033[32m'
    readonly C_GRAY=$'\033[90m'
    readonly C_RED=$'\033[31m'
    readonly C_CYAN=$'\033[36m'
else
    readonly IS_TTY=false
    readonly C_RESET='' C_GREEN='' C_GRAY='' C_RED='' C_CYAN=''
fi

# Runtime state (internal)
_OS="" _ARCH="" _DISTRO="" _MODE="" BREW_PREFIX=""
SUDO_KEEP_ALIVE_PID=""

# Output variables (exported)
export HOMEUP_OS="" HOMEUP_ARCH="" HOMEUP_DISTRO="" HOMEUP_MODE=""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Pre-flight Checks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_dependencies() {
    local deps=("curl" "git")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        msg_fail "Missing required dependencies: ${missing[*]}"
        msg_info "Please install them and run this script again."
        exit 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Output
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

msg_ok()   { printf "%s[OK]%s   %s\n" "$C_GREEN" "$C_RESET" "$1"; }
msg_skip() { printf "%s[SKIP]%s %s\n" "$C_GRAY" "$C_RESET" "$1"; }
msg_fail() { printf "%s[FAIL]%s %s\n" "$C_RED" "$C_RESET" "$1" >&2; }
msg_info() { printf "       %s\n" "$1"; }

die() {
    msg_fail "$1"
    exit "${2:-1}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Spinner
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

spinner() {
    local pid=$1 message=$2
    local frame=0 delay=0.1

    if [[ "$IS_TTY" != true ]]; then
        printf "       %s\n" "$message"
        wait "$pid" 2>/dev/null
        return $?
    fi

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r\033[K%s%s%s %s" "$C_CYAN" "${SPINNER_FRAMES:frame:1}" "$C_RESET" "$message"
        frame=$(( (frame + 1) % ${#SPINNER_FRAMES} ))
        sleep "$delay"
    done
    printf "\r\033[K"

    wait "$pid" 2>/dev/null
    return $?
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Cleanup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cleanup() {
    trap - EXIT INT TERM
    if [[ -n "${SUDO_KEEP_ALIVE_PID:-}" ]] && kill -0 "$SUDO_KEEP_ALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT
trap 'printf "\n"; die "Interrupted by user" 130' INT TERM

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Prerequisites
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_bash_version() {
    if [[ -z "${BASH_VERSION:-}" ]] || [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        die "Bash 4+ required (found: ${BASH_VERSION:-none})"
    fi
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Sudo
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

setup_sudo() {
    [[ $EUID -eq 0 ]] && die "Do not run as root. Use a normal user with sudo access."
    require_cmd sudo

    # In CI or non-interactive mode, check if we have passwordless sudo
    if [[ -n "${NONINTERACTIVE:-}" ]] || [[ -n "${CI:-}" ]]; then
        if ! sudo -n -v 2>/dev/null; then
            die "Passwordless sudo required in non-interactive mode"
        fi
    else
        # Interactive mode: prompt for password
        if ! sudo -v; then
            die "sudo authentication failed"
        fi
    fi

    (
        while sudo -n true 2>/dev/null; do
            sleep 50
        done
    ) &
    SUDO_KEEP_ALIVE_PID=$!

    msg_ok "Sudo credentials acquired"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# System Detection
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

detect_os() {
    local os
    os="$(uname -s)"

    case "$os" in
        Darwin) _OS="darwin" ;;
        Linux)  _OS="linux" ;;
        *)      die "Unsupported OS: $os" ;;
    esac

    HOMEUP_OS="$_OS"
    export HOMEUP_OS
}

detect_arch() {
    local arch
    arch="$(uname -m)"

    case "$arch" in
        x86_64)       _ARCH="x86_64" ;;
        amd64)        _ARCH="x86_64" ;;
        aarch64)      _ARCH="arm64" ;;
        arm64)        _ARCH="arm64" ;;
        *)            die "Unsupported architecture: $arch" ;;
    esac

    HOMEUP_ARCH="$_ARCH"
    export HOMEUP_ARCH
}

detect_distro() {
    if [[ "$_OS" == "darwin" ]]; then
        _DISTRO="macos"
    elif [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        local id="${ID:-unknown}"

        # Normalize to distro family
        case "$id" in
            ubuntu|debian|pop|mint|raspbian|kali)
                _DISTRO="debian"
                ;;
            fedora|rhel|centos|almalinux|rocky)
                _DISTRO="fedora"
                ;;
            arch|manjaro|endeavouros)
                _DISTRO="arch"
                ;;
            alpine)
                _DISTRO="alpine"
                ;;
            *)
                _DISTRO="$id"
                ;;
        esac
    else
        _DISTRO="unknown"
    fi

    HOMEUP_DISTRO="$_DISTRO"
    export HOMEUP_DISTRO
}

detect_mode() {
    # macOS is always workstation (has GUI by default)
    if [[ "$_OS" == "darwin" ]]; then
        _MODE="workstation"
        HOMEUP_MODE="$_MODE"
        export HOMEUP_MODE
        return 0
    fi

    # Linux: detect GUI environment
    local has_gui=false

    # Check for display server
    if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        has_gui=true
    fi

    # Check XDG session type
    if [[ "${XDG_SESSION_TYPE:-}" == "x11" ]] || [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        has_gui=true
    fi

    # Check for common desktop environment indicators
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || [[ -n "${DESKTOP_SESSION:-}" ]]; then
        has_gui=true
    fi

    if [[ "$has_gui" == true ]]; then
        _MODE="workstation"
    else
        _MODE="server"
    fi

    HOMEUP_MODE="$_MODE"
    export HOMEUP_MODE
}

detect_system() {
    detect_os
    detect_arch
    detect_distro
    detect_mode

    if [[ "$_OS" == "darwin" ]]; then
        msg_ok "Detected: macOS ($_ARCH, $_MODE)"
    else
        msg_ok "Detected: Linux/$_DISTRO ($_ARCH, $_MODE)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# macOS: Xcode CLI Tools
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_xcode_tools() {
    if xcode-select -p &>/dev/null; then
        msg_skip "Xcode Command Line Tools (already installed)"
        return 0
    fi

    msg_fail "Xcode Command Line Tools required"
    msg_info "Run: xcode-select --install"
    msg_info "Then re-run this script"
    exit 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Linux Dependencies
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_linux_deps() {
    if command -v git &>/dev/null && command -v curl &>/dev/null; then
        msg_skip "System dependencies (already installed)"
        return 0
    fi

    local update_cmd="" install_cmd="" packages=""

    case "$_DISTRO" in
        debian)
            update_cmd="sudo apt-get update -qq"
            install_cmd="sudo apt-get install -y -qq"
            packages="git curl build-essential procps file"
            ;;
        fedora)
            update_cmd="sudo dnf check-update -q || true"
            install_cmd="sudo dnf install -y -q"
            packages="git curl @development-tools procps-ng file"
            ;;
        arch)
            update_cmd="sudo pacman -Sy --noconfirm"
            install_cmd="sudo pacman -S --noconfirm --needed"
            packages="git curl base-devel procps-ng file"
            ;;
        alpine)
            update_cmd="sudo apk update -q"
            install_cmd="sudo apk add --no-cache -q"
            packages="git curl build-base procps file bash"
            ;;
        *)
            msg_skip "System dependencies (unsupported distro: $_DISTRO)"
            return 0
            ;;
    esac

    (
        $update_cmd >/dev/null 2>&1
        # shellcheck disable=SC2086
        $install_cmd $packages >/dev/null 2>&1
    ) &

    if spinner $! "Installing system dependencies"; then
        msg_ok "System dependencies installed"
    else
        die "Failed to install system dependencies"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Flatpak (Linux workstation only)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_flatpak() {
    # Only install on Linux workstation
    if [[ "$_OS" != "linux" ]] || [[ "$_MODE" != "workstation" ]]; then
        return 0
    fi

    if command -v flatpak &>/dev/null; then
        local version
        version=$(flatpak --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        msg_skip "Flatpak v$version (already installed)"
        return 0
    fi

    local install_cmd=""

    case "$_DISTRO" in
        debian)
            install_cmd="sudo apt-get install -y -qq flatpak"
            ;;
        fedora)
            # Fedora usually has flatpak pre-installed, but just in case
            install_cmd="sudo dnf install -y -q flatpak"
            ;;
        arch)
            install_cmd="sudo pacman -S --noconfirm --needed flatpak"
            ;;
        alpine)
            install_cmd="sudo apk add --no-cache -q flatpak"
            ;;
        *)
            msg_skip "Flatpak (unsupported distro: $_DISTRO)"
            return 0
            ;;
    esac

    (
        $install_cmd >/dev/null 2>&1
        # Add Flathub repository
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
    ) &

    if spinner $! "Installing Flatpak"; then
        if command -v flatpak &>/dev/null; then
            msg_ok "Flatpak installed (Flathub added)"
            return 0
        fi
    fi

    # Flatpak failure is not fatal, just warn
    msg_fail "Flatpak installation failed (non-fatal, continuing)"
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Homebrew
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

find_brew() {
    local paths=("/opt/homebrew" "/usr/local" "/home/linuxbrew/.linuxbrew" "$HOME/.linuxbrew")

    # Check if already in PATH
    if command -v brew >/dev/null 2>&1; then
        BREW_PREFIX="$(brew --prefix)"
        return 0
    fi

    # Check standard locations
    for prefix in "${paths[@]}"; do
        if [[ -x "$prefix/bin/brew" ]]; then
            BREW_PREFIX="$prefix"
            return 0
        fi
    done

    return 1
}

setup_brew_env() {
    [[ -z "$BREW_PREFIX" ]] && return 1
    [[ ! -x "$BREW_PREFIX/bin/brew" ]] && return 1

    # Always update PATH first so brew command works
    export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"

    # Then eval full shellenv
    if ! eval "$("$BREW_PREFIX/bin/brew" shellenv 2>/dev/null)"; then
        # Fallback: set essential variables
        export HOMEBREW_PREFIX="$BREW_PREFIX"
        export HOMEBREW_CELLAR="$BREW_PREFIX/Cellar"
        export HOMEBREW_REPOSITORY="$BREW_PREFIX/Homebrew"
    fi
    return 0
}

persist_brew_env() {
    [[ -z "$BREW_PREFIX" ]] && return 1
    [[ ! -x "$BREW_PREFIX/bin/brew" ]] && return 1

    mkdir -p "$(dirname "$BREW_SHELLENV_FILE")"

    # Generate shellenv content
    local shellenv_content
    if ! shellenv_content="$("$BREW_PREFIX/bin/brew" shellenv 2>/dev/null)" || [[ -z "$shellenv_content" ]]; then
        # Fallback: generate manually
        shellenv_content="export HOMEBREW_PREFIX=\"$BREW_PREFIX\"
export HOMEBREW_CELLAR=\"$BREW_PREFIX/Cellar\"
export HOMEBREW_REPOSITORY=\"$BREW_PREFIX/Homebrew\"
export PATH=\"$BREW_PREFIX/bin:$BREW_PREFIX/sbin:\${PATH+:\$PATH}\"
export MANPATH=\"$BREW_PREFIX/share/man\${MANPATH+:\$MANPATH}:\"
export INFOPATH=\"$BREW_PREFIX/share/info:\${INFOPATH:-}\""
    fi

    printf '%s\n' "$shellenv_content" > "$BREW_SHELLENV_FILE"
    chmod 644 "$BREW_SHELLENV_FILE"

    # Add sourcing snippet to shell profiles (idempotent)
    local marker="# Homebrew (Homeup Bootstrap)"
    # shellcheck disable=SC2016
    local snippet='[ -r "$HOME/.config/homebrew/shellenv" ] && . "$HOME/.config/homebrew/shellenv"'

    for profile in "$HOME/.zprofile" "$HOME/.profile" "$HOME/.bash_profile"; do
        # Skip if marker already present
        if [[ -f "$profile" ]] && grep -qF "$marker" "$profile" 2>/dev/null; then
            continue
        fi
        # Create file if not exists, append snippet
        printf '\n%s\n%s\n' "$marker" "$snippet" >> "$profile"
    done

    return 0
}

install_brew() {
    if find_brew; then
        setup_brew_env
        local version
        version=$(brew --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        persist_brew_env
        msg_skip "Homebrew v$version (already installed)"
        return 0
    fi

    require_cmd curl
    require_cmd bash

    (
        NONINTERACTIVE=1 bash -c "$(curl -fsSL "$BREW_INSTALL_URL")" >/dev/null 2>&1
    ) &

    if spinner $! "Installing Homebrew"; then
        if find_brew && setup_brew_env; then
            persist_brew_env
            msg_ok "Homebrew installed"
            return 0
        fi
    fi

    die "Homebrew installation failed"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Chezmoi
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_chezmoi() {
    if command -v chezmoi &>/dev/null; then
        local version
        version=$(chezmoi --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        msg_skip "chezmoi $version (already installed)"
        return 0
    fi

    require_cmd brew

    (
        brew install chezmoi >/dev/null 2>&1
    ) &

    if spinner $! "Installing chezmoi"; then
        if command -v chezmoi &>/dev/null; then
            msg_ok "chezmoi installed"
            return 0
        fi
    fi

    die "chezmoi installation failed"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_banner() {
    cat << 'EOF'
    __  __
   / / / /___  ____ ___  ___  __  ______
  / /_/ / __ \/ __ `__ \/ _ \/ / / / __ \
 / __  / /_/ / / / / / /  __/ /_/ / /_/ /
/_/ /_/\____/_/ /_/ /_/\___/\__,_/ .___/
                                /_/
EOF
    printf "Bootstrap v%s\n\n" "$SCRIPT_VERSION"
}

print_summary() {
    printf "\n"
    printf "%s━━━ Environment ━━━%s\n" "$C_CYAN" "$C_RESET"
    printf "  HOMEUP_OS      = %s\n" "$HOMEUP_OS"
    printf "  HOMEUP_ARCH    = %s\n" "$HOMEUP_ARCH"
    printf "  HOMEUP_DISTRO  = %s\n" "$HOMEUP_DISTRO"
    printf "  HOMEUP_MODE    = %s\n" "$HOMEUP_MODE"
    printf "\n"
}

main() {
    check_dependencies
    check_bash_version
    print_banner
    setup_sudo
    detect_system

    if [[ "$_OS" == "darwin" ]]; then
        check_xcode_tools
    elif [[ "$_OS" == "linux" ]]; then
        install_linux_deps
        install_flatpak
    fi

    install_brew
    install_chezmoi

    print_summary

    printf "%sBootstrap complete.%s\n" "$C_GREEN" "$C_RESET"
    printf "Restart your shell or run: source %s\n\n" "$BREW_SHELLENV_FILE"

    # Optional: Initialize dotfiles if DOTFILES_REPO is set
    if [[ -n "${DOTFILES_REPO:-}" ]]; then
        msg_info "Initializing dotfiles from ${DOTFILES_REPO}..."
        if chezmoi init --apply "$DOTFILES_REPO"; then
            msg_ok "Dotfiles initialized and applied"
        else
            msg_fail "Failed to initialize dotfiles"
        fi
    else
        printf "To initialize dotfiles, run:\n"
        printf "  chezmoi init --apply <your-repo-url>\n"
        printf "\nOr set DOTFILES_REPO environment variable before running this script.\n"
    fi
}

main "$@"
