#!/usr/bin/env bash
# ==============================================================================
# Homeup Bootstrap Script
# ==============================================================================
#
# Purpose: Layer 0 Bootstrap - Environment Detection + Base Tools
# Version: 6.2.0
# License: MIT
#
# Usage:
#   ./bootstrap.sh [OPTIONS]
#
# Options:
#   -p, --profile <name>    Profile: macos, linux, mini (Default: mini)
#   -r, --repo <repo>       Dotfiles repo (user/repo or full URL)
#   -a, --apply             Auto-apply chezmoi after init
#   -y, --yes               Non-interactive mode
#   -h, --help              Show this help message
#   -v, --version           Show version
#
# Default Behavior:
#   If no profile is specified, 'mini' is used. This is a "safe mode" that
#   installs minimal tools and does not touch sensitive keys (GPG/SSH).
#
# ==============================================================================

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Constants & Configuration
# ------------------------------------------------------------------------------

readonly SCRIPT_VERSION="6.2.0"
readonly BREW_SHELLENV_FILE="$HOME/.config/homebrew/shellenv"
readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly LOG_DIR="$HOME/.homeup/logs"
readonly LOG_FILE="$LOG_DIR/bootstrap.log"

# Configurable timeouts and retries (best practice defaults)
readonly CONNECTIVITY_TIMEOUT="${HOMEUP_CONNECTIVITY_TIMEOUT:-10}"
readonly DOWNLOAD_TIMEOUT="${HOMEUP_DOWNLOAD_TIMEOUT:-120}"
readonly RETRY_COUNT="${HOMEUP_RETRY_COUNT:-3}"
readonly RETRY_DELAY="${HOMEUP_RETRY_DELAY:-5}"

# UI Constants
readonly SPINNER_FRAMES='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
if [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
    readonly IS_TTY=true
    readonly C_RESET=$'\033[0m'
    readonly C_GREEN=$'\033[32m'
    readonly C_YELLOW=$'\033[33m'
    readonly C_RED=$'\033[31m'
    readonly C_CYAN=$'\033[36m'
else
    readonly IS_TTY=false
    readonly C_RESET='' C_GREEN='' C_YELLOW='' C_RED='' C_CYAN=''
fi

# Runtime State
_OS=""
_ARCH=""
_DISTRO=""
_PROFILE=""
SUDO_KEEP_ALIVE_PID=""

# Arguments
ARG_PROFILE=""
ARG_REPO=""
ARG_APPLY=false
ARG_YES=false

# Exported Variables
export HOMEUP_OS=""
export HOMEUP_ARCH=""
export HOMEUP_DISTRO=""
export HOMEUP_PROFILE=""
export BREW_PREFIX=""

# ------------------------------------------------------------------------------
# Logging & UI Utils
# ------------------------------------------------------------------------------

setup_logging() {
    mkdir -p "$LOG_DIR"
    # Rotate logs if larger than 5MB
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(wc -c <"$LOG_FILE" | xargs)
        if [[ $size -gt 5242880 ]]; then
            mv "$LOG_FILE" "$LOG_FILE.old"
        fi
    fi
    touch "$LOG_FILE"
    
    # Redirect a copy of stdout/stderr to log file
    # We use a subshell to avoid messing with current shell FDs if sourced
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
}

msg_ok()   { printf "%s[OK]%s   %s\n" "$C_GREEN" "$C_RESET" "$1"; }
msg_info() { printf "%s[INFO]%s %s\n" "$C_CYAN" "$C_RESET" "$1"; }
msg_warn() { printf "%s[WARN]%s %s\n" "$C_YELLOW" "$C_RESET" "$1"; }
msg_fail() { printf "%s[FAIL]%s %s\n" "$C_RED" "$C_RESET" "$1" >&2; }
msg_step() { printf "\n%s===>%s %s\n" "$C_CYAN" "$C_RESET" "$1"; }

die() {
    msg_fail "$1"
    exit "${2:-1}"
}

spinner() {
    local pid=$1
    local message=$2
    local frame=0
    local -r delay=0.1
    local exit_code

    if [[ "$IS_TTY" != true ]]; then
        printf "       %s...\n" "$message"
        wait "$pid" 2>/dev/null
        return $?
    fi

    # Hide cursor
    printf "\033[?25l"

    # Ensure cursor is restored on function exit
    trap 'printf "\033[?25h"' RETURN

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s%s%s %s" "$C_CYAN" "${SPINNER_FRAMES:frame:1}" "$C_RESET" "$message"
        frame=$(( (frame + 1) % ${#SPINNER_FRAMES} ))
        sleep "$delay"
    done

    # Clear line and restore cursor
    printf "\r\033[K"
    printf "\033[?25h"

    wait "$pid" 2>/dev/null
    exit_code=$?
    return "$exit_code"
}

# ------------------------------------------------------------------------------
# Argument Parsing
# ------------------------------------------------------------------------------

show_help() {
    cat <<EOF
Homeup Bootstrap v${SCRIPT_VERSION}

Usage: ./bootstrap.sh [OPTIONS]

Options:
  -p, --profile <name>    Profile to install (macos, linux, mini).
                          DEFAULT: 'mini' (Safe Mode)
  -r, --repo <url>        Dotfiles repository URL.
  -a, --apply             Auto-apply changes after init.
  -y, --yes               Non-interactive mode.
  -h, --help              Show this help.
  -v, --version           Show version.

Profiles:
  mini   (Default) Minimal tools. No GPG/Secret keys. Safe for any env.
  macos  Full environment for macOS (GUI apps, GPG, YubiKey).
  linux  Headless server environment (No GUI, SSH forwarding).

Environment Variables (Optional):
  HOMEUP_CONNECTIVITY_TIMEOUT    Network check timeout (default: 10s)
  HOMEUP_DOWNLOAD_TIMEOUT        Download timeout (default: 120s)
  HOMEUP_RETRY_COUNT             Retry attempts (default: 3)
  HOMEUP_RETRY_DELAY             Delay between retries (default: 5s)

Examples:
  ./bootstrap.sh                           # Installs 'mini' profile
  ./bootstrap.sh -p macos                  # Installs full macOS profile
  ./bootstrap.sh -p linux -y               # Installs Linux server (no prompt)
  HOMEUP_DOWNLOAD_TIMEOUT=300 ./bootstrap.sh  # Use 5 min timeout
EOF
}

validate_profile() {
    local profile=$1
    case "$profile" in
        macos|linux|mini)
            return 0
            ;;
        *)
            die "Invalid profile: $profile. Valid options: macos, linux, mini"
            ;;
    esac
}

validate_repo() {
    local repo=$1
    # Basic validation: check if it's a URL or user/repo format
    if [[ -z "$repo" ]]; then
        die "--repo requires a non-empty value"
    fi
    # Check for valid GitHub user/repo format or URL
    if [[ ! "$repo" =~ ^https?:// ]] && [[ ! "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
        die "Invalid repo format. Use 'user/repo' or full URL"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)
                if [[ -z "${2:-}" ]]; then
                    die "--profile requires an argument"
                fi
                validate_profile "$2"
                ARG_PROFILE="$2"
                shift 2
                ;;
            -r|--repo)
                if [[ -z "${2:-}" ]]; then
                    die "--repo requires an argument"
                fi
                validate_repo "$2"
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
                echo "v$SCRIPT_VERSION"
                exit 0
                ;;
            *)
                die "Unknown argument: $1"
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Robustness & Checks
# ------------------------------------------------------------------------------

check_disk_space() {
    local -r min_kb=$((2 * 1024 * 1024))  # 2GB in KB
    local avail_kb=""

    if ! command -v df >/dev/null 2>&1; then
        msg_warn "df command not found. Cannot verify disk space."
        return 0
    fi

    # Try POSIX output format (-P) if supported to avoid line wrapping
    local df_out
    if df -P . >/dev/null 2>&1; then
        df_out=$(df -Pk . | awk 'NR==2 {print $4}')
    else
        df_out=$(df -k . | awk 'NR==2 {print $4}')
    fi

    # Ensure it's a number
    if [[ "$df_out" =~ ^[0-9]+$ ]]; then
        avail_kb="$df_out"
    else
        msg_warn "Could not parse disk space. Continuing..."
        return 0
    fi

    if [[ "$avail_kb" -lt "$min_kb" ]]; then
        msg_warn "Low disk space: $((avail_kb/1024))MB available. Recommendation: 2GB+."
        # We warn but don't fail, as mini profile might fit.
    fi
}

check_internet_connection() {
    local -r test_url="https://github.com"

    if ! curl -Is --max-time "$CONNECTIVITY_TIMEOUT" "$test_url" >/dev/null 2>&1; then
        msg_fail "Cannot connect to GitHub. Please check your internet connection."
        msg_info "Timeout: ${CONNECTIVITY_TIMEOUT}s (override with HOMEUP_CONNECTIVITY_TIMEOUT)"
        return 1
    fi
    return 0
}

check_required_tools() {
    local -r required_tools=(git curl)
    local failed=0

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            msg_fail "Missing required tool: $tool"
            msg_info "Please install $tool using your system package manager first."
            failed=1
        fi
    done

    return "$failed"
}

check_prerequisites() {
    local failed=0

    # 1. Disk Space
    check_disk_space

    # 2. Internet Connection
    if ! check_internet_connection; then
        failed=1
    fi

    # 3. Basic Tools
    if ! check_required_tools; then
        failed=1
    fi

    if [[ $failed -eq 1 ]]; then
        die "Prerequisite checks failed."
    fi
}

setup_sudo() {
    # Ensure not running as root
    if [[ $EUID -eq 0 ]]; then
        die "Do not run as root. Run as normal user with sudo access."
    fi

    # Check if sudo is available
    if ! command -v sudo >/dev/null 2>&1; then
        msg_warn "Sudo not found. Some installations may fail."
        return 0
    fi

    # Refresh sudo credential cache
    if ! sudo -v 2>/dev/null; then
        if [[ "$ARG_YES" == true ]] || [[ -n "${CI:-}" ]]; then
            die "Passwordless sudo required for non-interactive mode."
        fi
        msg_info "Sudo password required for installation:"
        if ! sudo -v; then
            die "Sudo authentication failed."
        fi
    fi

    # Keep sudo alive in background
    (
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" 2>/dev/null || exit
        done
    ) &
    SUDO_KEEP_ALIVE_PID=$!
}

# ------------------------------------------------------------------------------
# Detection Logic
# ------------------------------------------------------------------------------

detect_system() {
    _OS="$(uname -s)"
    _ARCH="$(uname -m)"

    case "$_OS" in
        Darwin)
            _OS="darwin"
            _DISTRO="macos"
            ;;
        Linux)
            _OS="linux"
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                . /etc/os-release
                case "${ID:-}" in
                    ubuntu|debian|pop|kali) _DISTRO="debian" ;;
                    fedora|rhel|centos|almalinux) _DISTRO="fedora" ;;
                    *) _DISTRO="unknown" ;;
                esac
            else
                _DISTRO="unknown"
            fi
            ;;
        *) die "Unsupported OS: $_OS" ;;
    esac

    export HOMEUP_OS="$_OS"
    export HOMEUP_ARCH="$_ARCH"
    export HOMEUP_DISTRO="$_DISTRO"
}

decide_profile() {
    local selected=""

    if [[ -n "$ARG_PROFILE" ]]; then
        selected="$ARG_PROFILE"
        msg_ok "Profile selected via argument: $selected"
    elif [[ -n "${HOMEUP_PROFILE:-}" ]]; then
        selected="$HOMEUP_PROFILE"
        msg_ok "Profile selected via ENV: $selected"
    else
        selected="mini"
        msg_info "No profile specified. Defaulting to 'mini' (Safe Mode)."
        msg_info "To install a full environment, use: ./bootstrap.sh -p [macos|linux]"
    fi

    # Validation
    case "$selected" in
        macos)
            if [[ "$_OS" != "darwin" ]]; then
                msg_warn "Profile 'macos' requested but running on '$_OS'. Downgrading to 'linux'."
                selected="linux"
            fi
            ;;
        linux)
            ;;
        mini)
            ;;
        *)
            die "Invalid profile: $selected. Valid options: macos, linux, mini."
            ;;
    esac

    _PROFILE="$selected"
    export HOMEUP_PROFILE="$selected"
}

# ------------------------------------------------------------------------------
# Installers
# ------------------------------------------------------------------------------

install_debian_deps() {
    local -r packages=(build-essential procps file)

    export DEBIAN_FRONTEND=noninteractive

    msg_info "Updating package lists..."
    if ! sudo apt-get update -qq >/dev/null 2>&1; then
        msg_warn "apt-get update failed, continuing anyway..."
    fi

    msg_info "Installing system build dependencies..."
    if ! sudo apt-get install -y -qq "${packages[@]}" >/dev/null 2>&1; then
        msg_warn "Failed to install some system dependencies."
        return 1
    fi
    return 0
}

install_fedora_deps() {
    local -r packages=("@development-tools" procps-ng file)

    msg_info "Installing system build dependencies..."
    if ! sudo dnf install -y -q "${packages[@]}" >/dev/null 2>&1; then
        msg_warn "Failed to install some system dependencies."
        return 1
    fi
    return 0
}

install_system_deps() {
    # Only for Linux
    if [[ "$_OS" != "linux" ]]; then
        return 0
    fi

    case "$_DISTRO" in
        debian)
            install_debian_deps
            ;;
        fedora)
            install_fedora_deps
            ;;
        *)
            msg_warn "Unsupported distro for auto-dependency installation: $_DISTRO"
            return 0
            ;;
    esac
}

find_existing_homebrew() {
    local -r search_paths=(
        /opt/homebrew
        /usr/local
        /home/linuxbrew/.linuxbrew
    )

    for path in "${search_paths[@]}"; do
        if [[ -x "$path/bin/brew" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

configure_homebrew_env() {
    local brew_prefix=$1

    if [[ ! -x "$brew_prefix/bin/brew" ]]; then
        die "Homebrew binary not found at $brew_prefix/bin/brew"
    fi

    eval "$("$brew_prefix/bin/brew" shellenv)"
    BREW_PREFIX="$brew_prefix"

    # Persist ShellEnv
    mkdir -p "$(dirname "$BREW_SHELLENV_FILE")"
    "$brew_prefix/bin/brew" shellenv > "$BREW_SHELLENV_FILE"
}

install_homebrew() {
    local brew_prefix

    # Check if brew is already in PATH
    if command -v brew >/dev/null 2>&1; then
        msg_ok "Homebrew already installed."
        brew_prefix="$(brew --prefix)"
        BREW_PREFIX="$brew_prefix"
        return 0
    fi

    # Try to find Homebrew in standard paths
    if brew_prefix=$(find_existing_homebrew); then
        msg_ok "Found Homebrew at $brew_prefix"
        configure_homebrew_env "$brew_prefix"
        return 0
    fi

    # Install Homebrew
    msg_info "Installing Homebrew..."
    msg_info "Timeout: ${DOWNLOAD_TIMEOUT}s, Retries: ${RETRY_COUNT} (configurable via HOMEUP_* env vars)"

    local count=0

    while [[ $count -lt $RETRY_COUNT ]]; do
        ((count++))

        if NONINTERACTIVE=1 bash -c "$(curl -fsSL --max-time "$DOWNLOAD_TIMEOUT" "$BREW_INSTALL_URL")"; then
            # Determine installation prefix
            if [[ "$_OS" == "darwin" ]]; then
                if [[ -x "/opt/homebrew/bin/brew" ]]; then
                    brew_prefix="/opt/homebrew"
                else
                    brew_prefix="/usr/local"
                fi
            else
                brew_prefix="/home/linuxbrew/.linuxbrew"
            fi

            configure_homebrew_env "$brew_prefix"
            msg_ok "Homebrew installed successfully."
            return 0
        fi

        if [[ $count -lt $RETRY_COUNT ]]; then
            msg_warn "Homebrew installation failed (Attempt $count/$RETRY_COUNT). Retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
        fi
    done

    die "Failed to install Homebrew after $RETRY_COUNT attempts."
}

install_chezmoi() {
    if command -v chezmoi >/dev/null 2>&1; then
        msg_ok "Chezmoi already installed."
        return 0
    fi

    msg_info "Installing Chezmoi via Homebrew..."
    if brew install chezmoi 2>/dev/null; then
        msg_ok "Chezmoi installed via Homebrew."
        return 0
    fi

    # Fallback to direct installation
    msg_warn "Homebrew install failed. Trying direct installation..."
    local -r local_bin="$HOME/.local/bin"

    mkdir -p "$local_bin"

    if sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$local_bin"; then
        export PATH="$local_bin:$PATH"
        msg_ok "Chezmoi installed to $local_bin"
    else
        die "Failed to install Chezmoi via both Homebrew and direct installation."
    fi

    # Final verification
    if ! command -v chezmoi >/dev/null 2>&1; then
        die "Chezmoi installation verification failed."
    fi
}

is_local_repository() {
    [[ -f ".chezmoi.toml.tmpl" ]] || [[ -d ".git" ]]
}

build_chezmoi_command() {
    local repo_url=$1
    local is_local=$2
    local -a cmd=(chezmoi init)

    # Add apply flag if requested
    if [[ "$ARG_APPLY" == true ]]; then
        cmd+=(--apply)
    fi

    # Add source
    if [[ "$is_local" == true ]]; then
        cmd+=(--source .)
    else
        cmd+=("$repo_url")
    fi

    printf "%s" "${cmd[*]}"
}

initialize_dotfiles() {
    local repo_url="${ARG_REPO:-}"
    local is_local=false

    # Auto-detect local repository
    if [[ -z "$repo_url" ]]; then
        if is_local_repository; then
            msg_info "Detected local repository."
            is_local=true

            # Auto-enable apply if in local mode and defaulting to mini
            if [[ -z "$ARG_PROFILE" ]]; then
                ARG_APPLY=true
                msg_info "Auto-enabling --apply for local mini setup."
            fi
        fi
    fi

    # If no repo specified and not local, skip initialization
    if [[ -z "$repo_url" ]] && [[ "$is_local" != true ]]; then
        msg_info "No repository specified. Tools installed, but dotfiles not initialized."
        msg_info "To init later: chezmoi init --apply <your-repo>"
        return 0
    fi

    # Build and execute chezmoi command
    local chezmoi_cmd
    chezmoi_cmd=$(build_chezmoi_command "$repo_url" "$is_local")

    if [[ "$is_local" == true ]]; then
        msg_info "Initializing from local directory..."
    else
        msg_info "Initializing from $repo_url..."
    fi

    # Execute with proper error handling
    if eval "$chezmoi_cmd"; then
        msg_ok "Dotfiles initialized successfully!"
    else
        die "Failed to initialize dotfiles."
    fi
}

# ------------------------------------------------------------------------------
# Main Flow
# ------------------------------------------------------------------------------

cleanup() {
    if [[ -n "${SUDO_KEEP_ALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null || true
    fi
}

print_completion_message() {
    msg_step "Done!"
    msg_info "Profile applied: $HOMEUP_PROFILE"

    if [[ -f "$BREW_SHELLENV_FILE" ]]; then
        echo ""
        echo ">>> PLEASE RUN THIS COMMAND TO UPDATE YOUR SHELL: <<<"
        echo "    source $BREW_SHELLENV_FILE"
        echo ""
    fi
}

check_macos_prerequisites() {
    if ! xcode-select -p >/dev/null 2>&1; then
        msg_fail "Xcode CLI tools missing. Run: xcode-select --install"
        exit 1
    fi
}

main() {
    # Setup trap for cleanup
    trap cleanup EXIT

    # Parse command-line arguments
    parse_args "$@"

    # Initialize logging
    setup_logging

    # Step 1: System Detection
    msg_step "1. System Detection"
    detect_system
    msg_info "Detected: $_OS / $_DISTRO ($_ARCH)"

    # Step 2: Profile Selection
    msg_step "2. Profile Selection"
    decide_profile

    # Step 3: Prerequisites
    msg_step "3. Prerequisites"
    check_prerequisites
    setup_sudo

    # Platform-specific prerequisites
    if [[ "$_OS" == "darwin" ]]; then
        check_macos_prerequisites
    else
        install_system_deps
    fi

    # Step 4: Core Tools Installation
    msg_step "4. Core Tools Installation"
    install_homebrew
    install_chezmoi

    # Step 5: Dotfiles Initialization
    msg_step "5. Dotfiles Initialization"
    initialize_dotfiles

    # Completion
    print_completion_message
}

# Execute main function with all arguments
main "$@"
