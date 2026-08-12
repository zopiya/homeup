#!/usr/bin/env bash
# Creates a sudo user with key-only SSH login. This host-only operation is
# independent of firewall, hostname, timezone, and SSH hardening.
set -euo pipefail

NEW_USER="${NEW_USER:-}"
SSH_PUBKEY="${SSH_PUBKEY:-}"

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

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        error "must run as root (e.g. sudo bash scripts/host/create-user.sh)"
        exit 1
    }
}

non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }
valid_username() { [[ "$1" =~ ^[a-z_][a-z0-9_-]*$ ]]; }
valid_pubkey() { [[ "$1" =~ ^(ssh-ed25519|ssh-rsa|ssh-dss|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh\.com|sk-ecdsa-sha2-nistp256@openssh\.com)\ [A-Za-z0-9+/]+=*([[:space:]].*)?$ ]]; }

prompt_inputs() {
    if non_interactive; then
        if [[ -z "$NEW_USER" ]] || ! valid_username "$NEW_USER"; then
            error "NEW_USER='$NEW_USER' is invalid (must match ^[a-z_][a-z0-9_-]*\$)."
            exit 1
        fi
        valid_pubkey "$SSH_PUBKEY" || {
            error "SSH_PUBKEY is required and must be a valid public key line when running non-interactively."
            exit 1
        }
        return
    fi

    local reply
    while true; do
        read -r -p "New non-root username [$NEW_USER]: " reply
        reply="${reply:-$NEW_USER}"
        valid_username "$reply" && break
        warn "Invalid username '$reply' — try again."
    done
    NEW_USER="$reply"

    while [[ -z "$SSH_PUBKEY" ]] || ! valid_pubkey "$SSH_PUBKEY"; do
        [[ -n "$SSH_PUBKEY" ]] && warn "That does not look like an SSH public key — try again."
        read -r -p "Public key for $NEW_USER: " SSH_PUBKEY
    done
}

grant_passwordless_sudo() {
    local sudoers_file="/etc/sudoers.d/$NEW_USER" tmp
    tmp=$(mktemp)
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >"$tmp"
    if ! visudo -cf "$tmp" &>/dev/null; then
        error "generated sudoers entry for $NEW_USER failed validation"
        rm -f "$tmp"
        exit 1
    fi
    install -m 440 -o root -g root "$tmp" "$sudoers_file"
    rm -f "$tmp"
    log "Passwordless sudo granted to $NEW_USER"
}

create_user() {
    if id "$NEW_USER" &>/dev/null; then
        log "User $NEW_USER already exists, skipping creation"
    else
        adduser --disabled-password --gecos "" "$NEW_USER"
        usermod -aG sudo "$NEW_USER"
        log "Created user $NEW_USER (sudo group)"
    fi
    grant_passwordless_sudo

    local ssh_dir="/home/$NEW_USER/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"
    install -d -m 700 -o "$NEW_USER" -g "$NEW_USER" "$ssh_dir"
    touch "$auth_keys"
    grep -qxF "$SSH_PUBKEY" "$auth_keys" || echo "$SSH_PUBKEY" >>"$auth_keys"
    chmod 600 "$auth_keys"
    chown "$NEW_USER:$NEW_USER" "$auth_keys"
    log "Public key installed for $NEW_USER"
}

main() {
    require_root
    prompt_inputs
    create_user
    success "User $NEW_USER is ready."
    echo "Verify a separate SSH login before manually running host::ssh-harden."
}

main "$@"
