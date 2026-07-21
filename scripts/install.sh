#!/usr/bin/env bash
# homeup-linux one-shot Day 1 bootstrap: clones/updates the repo, installs
# just enough (`just`/`chezmoi`) to hand off, then delegates the actual
# install→setup→apply sequence to `just bootstrap` — that sequence lives in
# exactly one place (the justfile), not duplicated here. Intended to be
# hosted at a stable URL and run as:
#
#   curl -fsSL https://get.zopiya.dev/install | bash
#
# Safe to re-run any time afterwards to update — it's just `git pull` + a
# `just bootstrap` that's already idempotent on its own. Run as the non-root
# sudo user scripts/system/create-user.sh (or `just provision`) already
# created, never as root — see CLAUDE.md for why machine setup and package
# installation stay separate scripts.
#
# Piped through `curl | bash`, stdin is the script itself, not a terminal —
# so nothing here may prompt via `read`. Where a real password prompt is
# unavoidable (sudo), it's redirected from /dev/tty explicitly instead.
set -euo pipefail

REPO_URL="${HOMEUP_REPO_URL:-https://bfa307128a5b7cf8376d61c7956fe64022f91054@git.zopiya.dev/infra/homeup-linux.git}"
REPO_DIR="${HOMEUP_DIR:-/opt/homeup}"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_BLUE=$'\033[34m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_RESET=$'\033[0m'
else
    C_BLUE=''
    C_GREEN=''
    C_YELLOW=''
    C_RED=''
    C_RESET=''
fi
log() { echo "${C_BLUE}==>${C_RESET} $*"; }
success() { echo "${C_GREEN}✓${C_RESET} $*"; }
warn() { echo "${C_YELLOW}⚠${C_RESET} $*" >&2; }
error() { echo "${C_RED}✗${C_RESET} $*" >&2; }

require_non_root() {
    [[ "$(id -u)" -ne 0 ]] || {
        error "run this as your normal (non-root) user, not root."
        echo "  Haven't created that user yet? Run machine setup first: just provision (see README)." >&2
        exit 1
    }
}

require_apt() {
    command -v apt-get &>/dev/null || {
        error "apt-get not found. This installer targets Debian/Ubuntu."
        exit 1
    }
}

# Core support is Debian 12/13 and Ubuntu 24.04/26.04 (each distro's two most
# recent LTS releases) — other Debian/Ubuntu versions aren't blocked, just not
# a support target, so this only warns and continues.
check_os_support() {
    local id version_id pretty_name
    id=$(. /etc/os-release && echo "$ID")
    version_id=$(. /etc/os-release && echo "$VERSION_ID")
    pretty_name=$(. /etc/os-release && echo "$PRETTY_NAME")
    case "$id:$version_id" in
    debian:12 | debian:13 | ubuntu:24.04 | ubuntu:26.04) return ;;
    esac
    warn "unsupported OS: ${pretty_name:-$id $version_id}."
    echo "  Core support is Debian 12/13 and Ubuntu 24.04/26.04 — continuing anyway, but this combo isn't tested for. See CLAUDE.md." >&2
}

ensure_sudo() {
    sudo -n true 2>/dev/null && return
    if [[ -e /dev/tty ]]; then
        log "Needs sudo for package installation — you'll be prompted once."
        # shellcheck disable=SC2024 # redirect feeds sudo's password prompt, not sudo's own I/O
        sudo -v </dev/tty
    else
        error "sudo needs a password and there's no controlling terminal to ask on."
        echo "  Configure passwordless sudo for this user, or run this from an interactive shell." >&2
        exit 1
    fi
}

ensure_git() {
    already_installed git && return
    log "Installing git..."
    sudo apt-get install -y -qq git
}

already_installed() { command -v "$1" &>/dev/null; }

sync_repo() {
    if [[ -d "$REPO_DIR/.git" ]]; then
        log "Updating existing checkout at $REPO_DIR..."
        git -C "$REPO_DIR" pull --ff-only || {
            error "git pull failed in $REPO_DIR (local changes or diverged history?)."
            echo "  Resolve manually (commit/stash/rebase), then re-run." >&2
            exit 1
        }
    else
        log "Cloning $REPO_URL to $REPO_DIR..."
        # $REPO_DIR defaults under /opt, which this user doesn't own yet on a
        # fresh box — claim it once so future `git pull`s don't need sudo.
        # (init.sh already does this chown before handing off; this only
        # fires when install.sh is run standalone.)
        sudo mkdir -p "$REPO_DIR"
        sudo chown "$(id -u):$(id -g)" "$REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
    fi
}

# Installs only `just` and `chezmoi` — just enough to delegate the rest to
# `just bootstrap`. Deliberately not the full scripts/packages/install-tools.sh
# (that's `just install`'s job). Duplicates install-tools.sh's
# install_chezmoi/install_just one-liners rather than sourcing that script,
# for the same reason scripts/init.sh does: this entry script is meant to
# stand alone under `curl | bash`, without assuming anything else in the repo
# is a safe thing to source.
install_minimal_tools() {
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    already_installed chezmoi || sh -c "$(curl --connect-timeout 10 --max-time 180 -fsLS get.chezmoi.io)" -- -b "$bin_dir"
    already_installed just || curl --connect-timeout 10 --max-time 180 --proto '=https' --tlsv1.2 -fsSL https://just.systems/install.sh | bash -s -- --to "$bin_dir"
}

main() {
    require_non_root
    require_apt
    check_os_support
    ensure_sudo

    # A bare `bash scripts/install.sh` (no interactive login shell) won't have
    # ~/.local/bin on PATH yet — set it before install_minimal_tools's
    # already_installed checks run, or they'd always report "not installed"
    # (already on PATH is harmless to re-prepend, so do it unconditionally).
    export PATH="$HOME/.local/bin:$PATH"

    log "[1/4] Updating apt package lists..."
    sudo apt-get update -qq

    log "[2/4] Syncing $REPO_DIR..."
    ensure_git
    sync_repo

    log "[3/4] Installing just/chezmoi..."
    install_minimal_tools
    success "just/chezmoi ready"

    log "[4/4] Running Day 1 (just bootstrap)..."
    (cd "$REPO_DIR" && just bootstrap)

    echo ""
    success "homeup-linux bootstrap complete. Restart your shell: exec zsh -l"
    echo "Re-run this script any time to update."
}

main "$@"
