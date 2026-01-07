#!/usr/bin/env bash
# ==============================================================================
# Homeup Bootstrap Script
# ==============================================================================
#
# Purpose: Layer 0 Bootstrap - Environment Detection + Base Tools
# Version: 6.0.0
# License: MIT
#
# Usage:
#   ./bootstrap.sh [OPTIONS]
#
# Options:
#   -p, --profile <name>    Profile: workstation, codespace, server
#   -r, --repo <repo>       Dotfiles repo (user/repo or full URL)
#   -a, --apply             Auto-apply chezmoi after init
#   -y, --yes               Non-interactive mode
#   -h, --help              Show this help message
#   -v, --version           Show version
#
# Profiles:
#   workstation - Full trust: YubiKey/GPG, GUI apps, all packages
#   codespace   - Borrowed trust: SSH forwarding, CLI only, no GPG
#   server      - Zero trust: minimal packages, no private keys
#
# ==============================================================================

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

readonly SCRIPT_VERSION="6.0.0"
readonly BREW_SHELLENV_FILE="$HOME/.config/homebrew/shellenv"
readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly SPINNER_FRAMES='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
readonly PROFILE_CONFIRM_TIMEOUT=3

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
_OS="" _ARCH="" _DISTRO="" _PROFILE="" BREW_PREFIX=""
SUDO_KEEP_ALIVE_PID=""

# CLI arguments
ARG_PROFILE=""
ARG_REPO=""
ARG_APPLY=false
ARG_YES=false

# Output variables (exported)
export HOMEUP_OS="" HOMEUP_ARCH="" HOMEUP_DISTRO="" HOMEUP_PROFILE=""

# ------------------------------------------------------------------------------
# CLI Argument Parsing
# ------------------------------------------------------------------------------

show_help() {
    cat << 'EOF'
Homeup Bootstrap - Multi-Profile Dotfiles Setup

Usage: ./bootstrap.sh [OPTIONS]

Options:
  -p, --profile <name>    Profile: workstation, codespace, server
                          Default: auto-detect with interactive confirmation
  -r, --repo <repo>       Dotfiles repo for chezmoi init
                          Formats: user/repo, github.com/user/repo, full URL
  -a, --apply             Auto-apply chezmoi after init (use with --repo)
  -y, --yes               Non-interactive mode (skip confirmations)
  -h, --help              Show this help message
  -v, --version           Show version

Profiles:
  workstation   Full trust: YubiKey/GPG, GUI apps, all packages
  codespace     Borrowed trust: SSH forwarding, CLI only, no GPG
  server        Zero trust: minimal packages, no private keys

Examples:
  # Interactive (auto-detect profile)
  ./bootstrap.sh

  # Specify profile
  ./bootstrap.sh -p workstation

  # New machine one-liner (full automation)
  ./bootstrap.sh -p workstation -r zopiya/homeup -a

  # CI/Server automation (non-interactive)
  ./bootstrap.sh -p server -r zopiya/homeup -a -y

  # Remote execution
  curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash -s -- -p workstation -r zopiya/homeup -a

EOF
}

show_version() {
    printf "Homeup Bootstrap v%s\n" "$SCRIPT_VERSION"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)
                if [[ -z "${2:-}" ]]; then
                    printf "%s[ERROR]%s --profile requires a value\n" "$C_RED" "$C_RESET" >&2
                    exit 1
                fi
                ARG_PROFILE="$2"
                shift 2
                ;;
            -r|--repo)
                if [[ -z "${2:-}" ]]; then
                    printf "%s[ERROR]%s --repo requires a value\n" "$C_RED" "$C_RESET" >&2
                    exit 1
                fi
                ARG_REPO="$2"
                shift 2
                ;;
            -a|--apply)
                ARG_APPLY=true
                shift
                ;;
            -y|--yes)
                ARG_YES=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -*)
                printf "%s[ERROR]%s Unknown option: %s\n" "$C_RED" "$C_RESET" "$1" >&2
                printf "Use --help for usage information\n" >&2
                exit 1
                ;;
            *)
                printf "%s[ERROR]%s Unexpected argument: %s\n" "$C_RED" "$C_RESET" "$1" >&2
                exit 1
                ;;
        esac
    done

    # Validate --apply requires --repo
    if [[ "$ARG_APPLY" == true ]] && [[ -z "$ARG_REPO" ]]; then
        printf "%s[ERROR]%s --apply requires --repo to be specified\n" "$C_RED" "$C_RESET" >&2
        exit 1
    fi

    # Validate profile if provided
    if [[ -n "$ARG_PROFILE" ]]; then
        case "$ARG_PROFILE" in
            workstation|codespace|server) ;;
            *)
                printf "%s[ERROR]%s Invalid profile: %s\n" "$C_RED" "$C_RESET" "$ARG_PROFILE" >&2
                printf "Valid profiles: workstation, codespace, server\n" >&2
                exit 1
                ;;
        esac
    fi
}

# Normalize repo URL to full format
normalize_repo_url() {
    local repo="$1"

    # Already a full URL
    if [[ "$repo" =~ ^https?:// ]] || [[ "$repo" =~ ^git@ ]]; then
        echo "$repo"
        return
    fi

    # Format: github.com/user/repo or gitlab.com/user/repo
    if [[ "$repo" =~ ^(github|gitlab|bitbucket)\.(com|org)/ ]]; then
        echo "https://$repo"
        return
    fi

    # Format: user/repo (assume GitHub)
    if [[ "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
        echo "https://github.com/$repo"
        return
    fi

    # Return as-is if can't parse
    echo "$repo"
}

# ------------------------------------------------------------------------------
# Pre-flight Checks
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------

msg_ok()   { printf "%s[OK]%s   %s\n" "$C_GREEN" "$C_RESET" "$1"; }
msg_skip() { printf "%s[SKIP]%s %s\n" "$C_GRAY" "$C_RESET" "$1"; }
msg_fail() { printf "%s[FAIL]%s %s\n" "$C_RED" "$C_RESET" "$1" >&2; }
msg_info() { printf "       %s\n" "$1"; }

die() {
    msg_fail "$1"
    exit "${2:-1}"
}

# ------------------------------------------------------------------------------
# Spinner
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

cleanup() {
    trap - EXIT INT TERM
    if [[ -n "${SUDO_KEEP_ALIVE_PID:-}" ]] && kill -0 "$SUDO_KEEP_ALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT
trap 'printf "\n"; die "Interrupted by user" 130' INT TERM

# ------------------------------------------------------------------------------
# Prerequisites
# ------------------------------------------------------------------------------

check_bash_version() {
    if [[ -z "${BASH_VERSION:-}" ]] || [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        die "Bash 4+ required (found: ${BASH_VERSION:-none})"
    fi
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

# ------------------------------------------------------------------------------
# Sudo
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# System Detection
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# Profile Detection (3-in-1 Strategy)
# ------------------------------------------------------------------------------
# Priority:
#   1. HOMEUP_PROFILE environment variable (explicit override)
#   2. Auto-detection based on environment signals
#   3. Interactive confirmation with timeout (allows manual override)
# ------------------------------------------------------------------------------

auto_detect_profile() {
    # Codespace / DevContainer detection
    if [[ -n "${CODESPACES:-}" ]] || [[ -n "${REMOTE_CONTAINERS:-}" ]] || [[ -n "${VSCODE_REMOTE_CONTAINERS_SESSION:-}" ]]; then
        echo "codespace"
        return 0
    fi

    # GitHub Actions / CI detection -> treat as server
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "server"
        return 0
    fi

    # SSH session without display -> likely server
    if [[ -n "${SSH_CONNECTION:-}" ]] && [[ -z "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        echo "server"
        return 0
    fi

    # Linux headless detection
    if [[ "$_OS" == "linux" ]]; then
        local has_gui=false

        # Check for display server
        if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
            has_gui=true
        fi

        # Check XDG session type
        if [[ "${XDG_SESSION_TYPE:-}" == "x11" ]] || [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
            has_gui=true
        fi

        # Check for desktop environment
        if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || [[ -n "${DESKTOP_SESSION:-}" ]]; then
            has_gui=true
        fi

        if [[ "$has_gui" != true ]]; then
            echo "server"
            return 0
        fi
    fi

    # Default: workstation (macOS always, Linux with GUI)
    echo "workstation"
}

validate_profile() {
    local profile="$1"
    case "$profile" in
        workstation|codespace|server)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

detect_profile() {
    local detected_profile=""
    local final_profile=""

    # Priority 1: CLI argument (--profile)
    if [[ -n "$ARG_PROFILE" ]]; then
        _PROFILE="$ARG_PROFILE"
        HOMEUP_PROFILE="$_PROFILE"
        export HOMEUP_PROFILE
        msg_ok "Profile: $_PROFILE (from --profile)"
        return 0
    fi

    # Priority 2: Environment variable
    if [[ -n "${HOMEUP_PROFILE:-}" ]]; then
        if validate_profile "$HOMEUP_PROFILE"; then
            _PROFILE="$HOMEUP_PROFILE"
            export HOMEUP_PROFILE
            msg_ok "Profile: $_PROFILE (from HOMEUP_PROFILE env)"
            return 0
        else
            msg_fail "Invalid HOMEUP_PROFILE value: $HOMEUP_PROFILE"
            msg_info "Valid profiles: workstation, codespace, server"
            # Fall through to auto-detection
        fi
    fi

    # Priority 3: Auto-detection
    detected_profile="$(auto_detect_profile)"

    # Priority 4: Interactive confirmation (with timeout)
    # Skip if --yes flag or non-interactive mode
    if [[ "$ARG_YES" != true ]] && [[ "$IS_TTY" == true ]] && [[ -z "${CI:-}" ]]; then
        printf "\n"
        printf "%sDetected profile:%s %s\n" "$C_CYAN" "$C_RESET" "$detected_profile"
        printf "Press Enter to confirm, or type "
        printf "%sworkstation%s / %scodespace%s / %sserver%s to override\n" \
            "$C_GREEN" "$C_RESET" "$C_CYAN" "$C_RESET" "$C_GRAY" "$C_RESET"
        printf "[%ds timeout] > " "$PROFILE_CONFIRM_TIMEOUT"

        local user_input=""
        if read -t "$PROFILE_CONFIRM_TIMEOUT" -r user_input; then
            # User provided input
            user_input="${user_input,,}"  # lowercase
            user_input="${user_input// /}" # trim spaces

            if [[ -n "$user_input" ]]; then
                if validate_profile "$user_input"; then
                    final_profile="$user_input"
                    printf "\033[A\033[K"  # Clear the input line
                    msg_ok "Profile: $final_profile (user override)"
                else
                    printf "\033[A\033[K"
                    msg_fail "Invalid profile: $user_input (using detected: $detected_profile)"
                    final_profile="$detected_profile"
                fi
            else
                # Empty input = confirm detected
                printf "\033[A\033[K"
                msg_ok "Profile: $detected_profile (confirmed)"
                final_profile="$detected_profile"
            fi
        else
            # Timeout - use detected
            printf "\n"
            msg_ok "Profile: $detected_profile (auto-confirmed after ${PROFILE_CONFIRM_TIMEOUT}s)"
            final_profile="$detected_profile"
        fi
    else
        # Non-interactive mode (--yes or CI)
        final_profile="$detected_profile"
        msg_ok "Profile: $final_profile (auto-detected)"
    fi

    _PROFILE="$final_profile"
    HOMEUP_PROFILE="$_PROFILE"
    export HOMEUP_PROFILE
}

detect_system() {
    detect_os
    detect_arch
    detect_distro

    if [[ "$_OS" == "darwin" ]]; then
        msg_ok "System: macOS ($_ARCH)"
    else
        msg_ok "System: Linux/$_DISTRO ($_ARCH)"
    fi

    # Profile detection happens after system detection
    detect_profile
}

# ------------------------------------------------------------------------------
# macOS: Xcode CLI Tools
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# Linux Dependencies
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# Flatpak (Linux workstation only)
# ------------------------------------------------------------------------------

install_flatpak() {
    # Only install on Linux workstation profile
    if [[ "$_OS" != "linux" ]] || [[ "$_PROFILE" != "workstation" ]]; then
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

# ------------------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# Chezmoi
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

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
    printf "  HOMEUP_PROFILE = %s\n" "$HOMEUP_PROFILE"
    printf "\n"
}

main() {
    # Parse CLI arguments first
    parse_args "$@"

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

    # Initialize dotfiles if --repo is specified
    local repo_url=""
    if [[ -n "$ARG_REPO" ]]; then
        repo_url="$(normalize_repo_url "$ARG_REPO")"
    elif [[ -n "${DOTFILES_REPO:-}" ]]; then
        repo_url="$(normalize_repo_url "$DOTFILES_REPO")"
    fi

    if [[ -n "$repo_url" ]]; then
        printf "\n"
        msg_info "Initializing dotfiles from: $repo_url"

        # Build chezmoi command
        local chezmoi_args=("init")

        # Pass profile to chezmoi via --promptString
        chezmoi_args+=("--promptString" "profile=$HOMEUP_PROFILE")

        if [[ "$ARG_APPLY" == true ]]; then
            chezmoi_args+=("--apply")
        fi

        chezmoi_args+=("$repo_url")

        if chezmoi "${chezmoi_args[@]}"; then
            msg_ok "Dotfiles initialized"
            if [[ "$ARG_APPLY" == true ]]; then
                msg_ok "Configuration applied"
            else
                printf "\nTo apply configuration, run:\n"
                printf "  chezmoi apply\n"
            fi
        else
            msg_fail "Failed to initialize dotfiles"
            exit 1
        fi
    else
        printf "\n%sNext steps:%s\n" "$C_CYAN" "$C_RESET"
        printf "  Initialize dotfiles:\n"
        printf "    chezmoi init --apply <your-repo>\n"
        printf "\n  Or re-run with --repo:\n"
        printf "    ./bootstrap.sh --repo <your-repo> --apply\n"
    fi
}

main "$@"
