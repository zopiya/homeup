#!/usr/bin/env bash
# homeup-linux Day 0 root orchestrator: clones/updates the repo into /opt,
# runs Day 0 provisioning non-interactively via env vars, hands the checkout
# off to the new user, then cascades straight into their Day 1 bootstrap
# (install.sh). Intended to be hosted at a stable URL and run as root:
#
#   export NEW_USER=zopiya SSH_PUBKEY="ssh-ed25519 AAAA... you@laptop"
#   curl -fsSL https://get.zopiya.dev/init | sudo -E bash
#
# (`-E` matters: plain `sudo bash` resets the environment and NEW_USER/
# SSH_PUBKEY would never reach the script. Already logged in as literal
# root? Drop `sudo -E` entirely and just pipe into `bash`.)
#
# SSH hardening (disabling root/password login) is deliberately NOT part of
# this cascade — packages/server-init.sh never does that unattended, and
# neither does this script. Verify the new login works, then harden it
# yourself; see the instructions server-init.sh prints at the end of its run.
#
# Root does root's job here (create the user, firewall, hand off ownership
# of the checkout); everything past that point runs as the new user, never
# as root — see CLAUDE.md for why Day 0/Day 1 stay separate scripts.
set -euo pipefail

NEW_USER="${NEW_USER:-zopiya}"
REPO_URL="${HOMEUP_REPO_URL:-https://github.com/zopiya/homeup-linux.git}"
REPO_DIR="${HOMEUP_DIR:-/opt/homeup-linux}"

log() { echo "==> $*"; }
already_installed() { command -v "$1" &>/dev/null; }

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "Error: run this as root (e.g. sudo -E bash root-install.sh)." >&2
        exit 1
    }
}

require_apt() {
    command -v apt-get &>/dev/null || {
        echo "Error: apt-get not found. This installer targets Debian/Ubuntu." >&2
        exit 1
    }
}

ensure_git() {
    already_installed git && return
    log "Installing git..."
    apt-get update -qq
    apt-get install -y -qq git
}

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
        mkdir -p "$(dirname "$REPO_DIR")"
        git clone "$REPO_URL" "$REPO_DIR"
    fi
}

main() {
    require_root
    require_apt
    ensure_git
    sync_repo

    log "Running Day 0 provisioning (packages/server-init.sh)..."
    bash "$REPO_DIR/packages/server-init.sh"

    log "Handing $REPO_DIR off to $NEW_USER..."
    chown -R "$NEW_USER:$NEW_USER" "$REPO_DIR"

    log "Cascading into Day 1 as $NEW_USER..."
    su - "$NEW_USER" -c "HOMEUP_DIR='$REPO_DIR' HOMEUP_REPO_URL='$REPO_URL' bash '$REPO_DIR/install.sh'"

    echo ""
    echo "=== root-install.sh complete ==="
    echo "Day 0 (minus SSH hardening) and Day 1 are both done for $NEW_USER."
    echo "Verify you can log in as $NEW_USER, then harden SSH yourself — see the"
    echo "instructions packages/server-init.sh printed above."
}

main "$@"
