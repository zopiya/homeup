#!/usr/bin/env bash
# homeup-linux root entry point: clones/updates the repo into /opt, runs the
# machine-level setup (create user, SSH key, firewall, hostname/timezone) as
# root, hands the checkout off to the new user, and installs just enough
# (`just` + `chezmoi` themselves) for that user to take it from there. It
# deliberately stops after that — it does NOT install packages or apply
# dotfiles. Intended to be hosted at a stable URL and run as root:
#
#   curl -fsSL https://get.zopiya.dev/init | sudo -E bash
#
# NEW_USER and SSH_PUBKEY are required explicit inputs. (`-E` matters: plain
# `sudo bash` resets the environment and these variables would never reach the
# script. Already logged in as literal root? Drop `sudo -E` entirely.)
#
# SSH hardening (disabling root/password login) is deliberately NOT part of
# this script — that's scripts/system/ssh-harden.sh's job, and it never runs
# unattended, no matter how it's invoked. Verify the new login works, then
# run it yourself (`just scripts::ssh-harden`), separately, on purpose.
#
# Root does root's job here (create the user, firewall, hand off ownership of
# the checkout, install just/chezmoi); everything past that point — installing
# packages and applying dotfiles — is a deliberate manual step you run
# yourself as the new user (`just bootstrap`, or scripts/install.sh), never
# automatically and never as root.
set -euo pipefail

NEW_USER="${NEW_USER:-}"
REPO_URL="${HOMEUP_REPO_URL:-https://github.com/zopiya/homeup.git}"
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
already_installed() { command -v "$1" &>/dev/null; }

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        error "run this as root (e.g. sudo -E bash init.sh)."
        exit 1
    }
}

require_apt() {
    command -v apt-get &>/dev/null || {
        error "apt-get not found. This installer targets Debian/Ubuntu."
        exit 1
    }
}

require_host_inputs() {
    [[ -n "$NEW_USER" && -n "${SSH_PUBKEY:-}" ]] || {
        error 'NEW_USER and SSH_PUBKEY are required for legacy host initialization.'
        echo "  Example: export NEW_USER=dev SSH_PUBKEY='ssh-ed25519 AAAA... laptop'; curl -fsSL https://get.zopiya.dev/init | sudo -E bash" >&2
        exit 1
    }
}

# Core support is Debian 12/13 and Ubuntu 24.04/26.04 (each distro's two most
# recent LTS releases) — other Debian/Ubuntu versions aren't blocked, just not
# a support target, so this only warns and continues.
check_os_support() {
    local id version_id pretty_name
    # shellcheck disable=SC1091,SC2153
    id=$(. /etc/os-release && echo "$ID")
    # shellcheck disable=SC1091,SC2153
    version_id=$(. /etc/os-release && echo "$VERSION_ID")
    # shellcheck disable=SC1091,SC2153
    pretty_name=$(. /etc/os-release && echo "$PRETTY_NAME")
    case "$id:$version_id" in
    debian:12 | debian:13 | ubuntu:24.04 | ubuntu:26.04) return ;;
    esac
    warn "unsupported OS: ${pretty_name:-$id $version_id}."
    echo "  Core support is Debian 12/13 and Ubuntu 24.04/26.04 — continuing anyway, but this combo isn't tested for. See CLAUDE.md." >&2
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
            error "git pull failed in $REPO_DIR (local changes or diverged history?)."
            echo "  Resolve manually (commit/stash/rebase), then re-run." >&2
            exit 1
        }
    else
        log "Cloning $REPO_URL to $REPO_DIR..."
        mkdir -p "$(dirname "$REPO_DIR")"
        git clone "$REPO_URL" "$REPO_DIR"
    fi
}

# The v1 bootstrap owns locked CLI installation. This legacy Day 0 helper only
# creates/provisions the host and hands the checkout to the target user.
install_minimal_tools() {
    su - "$NEW_USER" -c "HOMEUP_DIR='$REPO_DIR' bash '$REPO_DIR/scripts/bootstrap/bootstrap-just.sh' >/dev/null"
    success "locked just installed for $NEW_USER"
}

main() {
    require_root
    require_apt
    require_host_inputs
    check_os_support
    ensure_git
    sync_repo

    log "[1/5] Creating user..."
    bash "$REPO_DIR/scripts/system/create-user.sh"

    log "[2/5] Configuring firewall..."
    bash "$REPO_DIR/scripts/system/ufw.sh"

    log "[3/5] Setting hostname..."
    bash "$REPO_DIR/scripts/system/hostname.sh"

    log "[4/5] Setting timezone..."
    bash "$REPO_DIR/scripts/system/timezone.sh"

    log "[5/5] Handing $REPO_DIR off to $NEW_USER and installing just/chezmoi..."
    chown -R "$NEW_USER:$NEW_USER" "$REPO_DIR"
    install_minimal_tools

    echo ""
    success "init.sh complete — $NEW_USER exists, $REPO_DIR is cloned, and locked just is installed."
    echo ""
    echo "${C_YELLOW}Next:${C_RESET} verify you can log in as $NEW_USER, then — and only then — harden SSH yourself:"
    echo "  cd $REPO_DIR && NEW_USER=$NEW_USER just scripts::ssh-harden"
    echo ""
    echo "Once that's confirmed, log in as $NEW_USER and finish setup yourself, e.g.:"
    echo "  cd $REPO_DIR && just bootstrap        # install packages/tools, apply dotfiles"
    echo "or, without just:"
    echo "  curl -fsSL https://get.zopiya.dev/install | bash"
}

main "$@"
