#!/usr/bin/env bash
# ==============================================================================
# Homeup Bootstrap Script
# ==============================================================================
#
# Purpose: Layer 0 Bootstrap - Environment Detection + Base Tools
# Version: 6.1.0
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

readonly SCRIPT_VERSION="6.1.0"
readonly BREW_SHELLENV_FILE="$HOME/.config/homebrew/shellenv"
readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly LOG_DIR="$HOME/.homeup/logs"
readonly LOG_FILE="$LOG_DIR/bootstrap.log"

# UI Constants
readonly SPINNER_FRAMES='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
if [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
    readonly IS_TTY=true
    readonly C_RESET=$'\033[0m'
    readonly C_GREEN=$'\033[32m'
    readonly C_YELLOW=$'\033[33m'
    readonly C_RED=$'\033[31m'
    readonly C_CYAN=$'\033[36m'
    readonly C_GRAY=$'\033[90m'
else
    readonly IS_TTY=false
    readonly C_RESET='' C_GREEN='' C_YELLOW='' C_RED='' C_CYAN='' C_GRAY=''
fi

# Runtime State
_OS=""
_ARCH=""
_DISTRO=""
_PROFILE=""
BREW_PREFIX=""
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
    local pid=$1 message=$2
    local frame=0 delay=0.1

    if [[ "$IS_TTY" != true ]]; then
        printf "       %s...\n" "$message"
        wait "$pid" 2>/dev/null
        return $?
    fi

    # Hide cursor
    printf "\033[?25l"

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s%s%s %s" "$C_CYAN" "${SPINNER_FRAMES:frame:1}" "$C_RESET" "$message"
        frame=$(((frame + 1) % ${#SPINNER_FRAMES}))
        sleep "$delay"
    done
    
    # Clear line and restore cursor
    printf "\r\033[K"
    printf "\033[?25h"

    wait "$pid" 2>/dev/null
    return $?
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

Profiles:
  mini   (Default) Minimal tools. No GPG/Secret keys. Safe for any env.
  macos  Full environment for macOS (GUI apps, GPG, YubiKey).
  linux  Headless server environment (No GUI, SSH forwarding).

Examples:
  ./bootstrap.sh                  # Installs 'mini' profile
  ./bootstrap.sh -p macos         # Installs full macOS profile
  ./bootstrap.sh -p linux -y      # Installs Linux server profile (no prompt)
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)
                if [[ -z "${2:-}" ]]; then die "--profile requires an argument"; fi
                ARG_PROFILE="$2"
                shift 2 ;;
            -r|--repo)
                if [[ -z "${2:-}" ]]; then die "--repo requires an argument"; fi
                ARG_REPO="$2"
                shift 2 ;;
            -a|--apply) ARG_APPLY=true; shift ;; 
            -y|--yes)   ARG_YES=true; shift ;; 
            -h|--help)  show_help; exit 0 ;; 
            -v|--version) echo "v$SCRIPT_VERSION"; exit 0 ;; 
            *)
                die "Unknown argument: $1"
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Robustness & Checks
# ------------------------------------------------------------------------------

check_prerequisites() {
    local failed=0

    # 1. Disk Space (need ~2GB conservatively for tools + brew)
    local min_kb=$((2 * 1024 * 1024))
    local avail_kb
    avail_kb=$(df -k . | awk 'NR==2 {print $4}')
    if [[ "$avail_kb" -lt "$min_kb" ]]; then
        msg_warn "Low disk space: $((avail_kb/1024))MB available. Recommendation: 2GB+."
        # We warn but don't fail, as mini profile might fit.
    fi

    # 2. Internet Connection
    if ! curl -Is --max-time 5 https://github.com >/dev/null; then
        msg_fail "Cannot connect to GitHub. Please check your internet connection."
        failed=1
    fi

    # 3. Basic Tools
    for tool in git curl; do
        if ! command -v "$tool" >/dev/null; then
            msg_fail "Missing required tool: $tool"
            msg_info "Please install $tool using your system package manager first."
            failed=1
        fi
    done

    [[ $failed -eq 1 ]] && die "Prerequisite checks failed."
}

setup_sudo() {
    [[ $EUID -eq 0 ]] && die "Do not run as root. Run as normal user with sudo access."
    
    if ! command -v sudo >/dev/null; then
        msg_warn "Sudo not found. Some installations may fail."
        return
    fi

    # Refresh sudo credential cache
    if ! sudo -v 2>/dev/null; then
        if [[ "$ARG_YES" == true || -n "${CI:-}" ]]; then
            die "Passwordless sudo required for non-interactive mode."
        fi
        msg_info "Sudo password required for installation:"
        sudo -v || die "Sudo authentication failed."
    fi

    # Keep sudo alive
    ( while true; do sudo -n true; sleep 60; kill -0 "$$ " || exit; done 2>/dev/null ) &
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
    # STRATEGY:
    # 1. Explicit Argument (-p) wins.
    # 2. Environment Variable (HOMEUP_PROFILE) comes second.
    # 3. Default fallback is ALWAYS 'mini'.

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
            # Linux profile is headless server
            ;;
        mini)
            # Safe everywhere
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

install_system_deps() {
    [[ "$_OS" != "linux" ]] && return 0

    local install_cmd=""
    local packages=""

    case "$_DISTRO" in
        debian)
            install_cmd="sudo apt-get install -y -qq"
            packages="build-essential procps file"
            # Update apt first
            sudo apt-get update -qq >/dev/null 2>&1 || true
            ;;
        fedora)
            install_cmd="sudo dnf install -y -q"
            packages="@development-tools procps-ng file"
            ;;
        *)
            msg_warn "Unsupported distro for auto-dependency installation: $_DISTRO"
            return 0
            ;;
    esac

    msg_info "Installing system build dependencies..."
    $install_cmd $packages >/dev/null 2>&1 || msg_warn "Failed to install some system dependencies."
}

install_homebrew() {
    # Check existing
    if command -v brew >/dev/null; then
        msg_ok "Homebrew already installed."
        BREW_PREFIX="$(brew --prefix)"
        return 0
    fi
    
    # Try standard paths if not in PATH
    for path in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
        if [[ -x "$path/bin/brew" ]]; then
            msg_ok "Found Homebrew at $path"
            eval "$($path/bin/brew shellenv)"
            BREW_PREFIX="$path"
            return 0
        fi
    done

    msg_info "Installing Homebrew..."
    
    local retries=3
    local count=0
    local success=false

    while [[ $count -lt $retries ]]; do
        ((count++))
        if NONINTERACTIVE=1 bash -c "$(curl -fsSL --max-time 60 "$BREW_INSTALL_URL")"; then
            success=true
            break
        fi
        msg_warn "Homebrew installation failed (Attempt $count/$retries). Retrying..."
        sleep 3
    done

    if [[ "$success" == false ]]; then
        die "Failed to install Homebrew after $retries attempts."
    fi

    # Configure ShellEnv
    local found_prefix=""
    if [[ "$_OS" == "darwin" ]]; then
        [[ -x "/opt/homebrew/bin/brew" ]] && found_prefix="/opt/homebrew" || found_prefix="/usr/local"
    else
        found_prefix="/home/linuxbrew/.linuxbrew"
    fi

    eval "$($found_prefix/bin/brew shellenv)"
    BREW_PREFIX="$found_prefix"
    
    # Persist ShellEnv
    mkdir -p "$(dirname "$BREW_SHELLENV_FILE")"
    "$BREW_PREFIX/bin/brew" shellenv > "$BREW_SHELLENV_FILE"
    
    msg_ok "Homebrew installed successfully."
}

install_chezmoi() {
    if command -v chezmoi >/dev/null; then
        msg_ok "Chezmoi already installed."
        return 0
    fi

    msg_info "Installing Chezmoi via Homebrew..."
    if ! brew install chezmoi; then
        msg_warn "Homebrew install failed. Trying curl fallback..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if ! command -v chezmoi >/dev/null; then
        die "Failed to install Chezmoi."
    fi
    msg_ok "Chezmoi installed."
}

# ------------------------------------------------------------------------------
# Main Flow
# ------------------------------------------------------------------------------

cleanup() {
    [[ -n "${SUDO_KEEP_ALIVE_PID:-}" ]] && kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null
}
trap cleanup EXIT

main() {
    setup_logging
    parse_args "$@"
    
    msg_step "1. System Detection"
    detect_system
    msg_info "Detected: $_OS / $_DISTRO ($_ARCH)"
    
    msg_step "2. Profile Selection"
    decide_profile
    
    msg_step "3. Prerequisites"
    check_prerequisites
    setup_sudo
    
    if [[ "$_OS" == "darwin" ]]; then
        if ! xcode-select -p >/dev/null 2>&1; then
            msg_fail "Xcode CLI tools missing. Run: xcode-select --install"
            exit 1
        fi
    else
        install_system_deps
    fi
    
    msg_step "4. Core Tools Installation"
    install_homebrew
    install_chezmoi
    
    msg_step "5. Dotfiles Initialization"
    
    local repo_url="${ARG_REPO:-}"
    # Default repo if not provided? (Optional, maybe zopiya/homeup)
    # If no repo provided, we just setup the tools and exit.
    
    if [[ -n "$repo_url" ]]; then
        local chezmoi_cmd="chezmoi init --promptString profile=$HOMEUP_PROFILE"
        [[ "$ARG_APPLY" == true ]] && chezmoi_cmd="$chezmoi_cmd --apply"
        
        msg_info "Initializing from $repo_url..."
        if $chezmoi_cmd "$repo_url"; then
            msg_ok "Dotfiles initialized successfully!"
        else
            die "Failed to initialize dotfiles."
        fi
    else
        msg_info "No repository specified. Tools installed, but dotfiles not initialized."
        msg_info "To init later: chezmoi init --apply <your-repo>"
    fi
    
    msg_step "Done!"
    msg_info "Profile applied: $HOMEUP_PROFILE"
    if [[ -f "$BREW_SHELLENV_FILE" ]]; then
        echo ""
        echo ">>> PLEASE RUN THIS COMMAND TO UPDATE YOUR SHELL: <<<"
        echo "    source $BREW_SHELLENV_FILE"
        echo ""
    fi
}

main "$@"