#!/usr/bin/env bash
# homeup-linux one-shot Day 1 bootstrap: clones/updates the repo, installs
# apt packages + upstream tools, applies dotfiles via chezmoi, and runs
# `just setup`. Intended to be hosted at a stable URL and run as:
#
#   curl -fsSL https://xx.zopiya.dev/init.sh | bash
#
# Safe to re-run any time afterwards to update — it's just `git pull` +
# re-running steps that are already idempotent on their own (apt install,
# install-tools.sh, chezmoi apply). Day 1 only: run as the non-root sudo
# user Day 0 (packages/server-init.sh) already created, never as root —
# see CLAUDE.md for why the two phases don't mix.
#
# Piped through `curl | bash`, stdin is the script itself, not a terminal —
# so nothing here may prompt via `read`. Where a real password prompt is
# unavoidable (sudo), it's redirected from /dev/tty explicitly instead.
set -euo pipefail

REPO_URL="${HOMEUP_REPO_URL:-https://github.com/zopiya/homeup-linux.git}"
REPO_DIR="${HOMEUP_DIR:-/opt/homeup-linux}"

log() { echo "==> $*"; }

require_non_root() {
    [[ "$(id -u)" -ne 0 ]] || {
        echo "Error: run this as your normal (non-root) user, not root." >&2
        echo "Haven't created that user yet? Run Day 0 first: packages/server-init.sh (see README)." >&2
        exit 1
    }
}

require_apt() {
    command -v apt-get &>/dev/null || {
        echo "Error: apt-get not found. This installer targets Debian/Ubuntu." >&2
        exit 1
    }
}

ensure_sudo() {
    sudo -n true 2>/dev/null && return
    if [[ -e /dev/tty ]]; then
        log "Needs sudo for package installation — you'll be prompted once."
        sudo -v </dev/tty
    else
        echo "Error: sudo needs a password and there's no controlling terminal to ask on." >&2
        echo "Configure passwordless sudo for this user, or run this from an interactive shell." >&2
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
            echo "Error: git pull failed in $REPO_DIR (local changes or diverged history?)." >&2
            echo "Resolve manually (commit/stash/rebase), then re-run." >&2
            exit 1
        }
    else
        log "Cloning $REPO_URL to $REPO_DIR..."
        # $REPO_DIR defaults under /opt, which this user doesn't own yet on a
        # fresh box — claim it once so future `git pull`s don't need sudo.
        # (root-install.sh's cascade already does this before handing off; this
        # only fires when install.sh is run standalone.)
        sudo mkdir -p "$REPO_DIR"
        sudo chown "$(id -u):$(id -g)" "$REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
    fi
}

install_packages() {
    log "Installing apt packages..."
    xargs -a "$REPO_DIR/packages/apt-packages.txt" sudo apt-get install -y -qq

    log "Installing upstream tools..."
    bash "$REPO_DIR/packages/install-tools.sh"
}

main() {
    require_non_root
    require_apt
    ensure_sudo

    log "Updating apt package lists..."
    sudo apt-get update -qq

    ensure_git
    sync_repo
    install_packages

    # install_packages just put chezmoi/just in ~/.local/bin; this process's
    # PATH won't see them until the next login, so add it now.
    export PATH="$HOME/.local/bin:$PATH"

    log "Applying dotfiles..."
    chezmoi init --source "$REPO_DIR" --apply

    log "Finishing setup..."
    (cd "$REPO_DIR" && just setup)

    echo ""
    echo "homeup-linux bootstrap complete. Restart your shell: exec zsh -l"
    echo "Re-run this script any time to update."
}

main "$@"
