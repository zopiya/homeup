#!/usr/bin/env bash
# Creates the sudo user with key-only SSH login. Independent of ufw.sh/
# hostname.sh/timezone.sh/ssh-harden.sh — run standalone, or compose with
# `just provision` (see scripts/justfile). Idempotent: safe to re-run.
set -euo pipefail

NEW_USER="${NEW_USER:-zopiya}"
SSH_PUBKEY="${SSH_PUBKEY:-ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQ4Av3vfRyFgRIBw/WMEiSb1r96MumJPqH0W31m7M+J zopiya}"

log() { echo "==> $*"; }

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "Error: must run as root (e.g. sudo bash create-user.sh)" >&2
        exit 1
    }
}

# No controlling terminal (e.g. invoked via `curl | bash` or composed from
# scripts/init.sh) means no `read` prompt can ever be answered — fall back to
# NEW_USER/SSH_PUBKEY env vars entirely instead of hanging on stdin.
# NONINTERACTIVE=1 forces the same path even from a real terminal.
non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }

valid_username() { [[ "$1" =~ ^[a-z_][a-z0-9_-]*$ ]]; }

# Loose but useful: catches pasted garbage (comments, private keys, truncated
# lines) before it lands in authorized_keys, without re-implementing a full
# SSH key-format parser.
valid_pubkey() { [[ "$1" =~ ^(ssh-ed25519|ssh-rsa|ssh-dss|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh\.com|sk-ecdsa-sha2-nistp256@openssh\.com)\ [A-Za-z0-9+/]+=*([[:space:]].*)?$ ]]; }

prompt_inputs() {
    if non_interactive; then
        valid_username "$NEW_USER" || {
            echo "Error: NEW_USER='$NEW_USER' is invalid (must match ^[a-z_][a-z0-9_-]*\$)." >&2
            exit 1
        }
        valid_pubkey "$SSH_PUBKEY" || {
            echo "Error: SSH_PUBKEY is required and must be a valid public key line when running non-interactively." >&2
            echo "Example: SSH_PUBKEY='ssh-ed25519 AAAA...' sudo -E bash scripts/system/create-user.sh" >&2
            exit 1
        }
        return
    fi

    local reply
    while true; do
        read -r -p "New non-root username [$NEW_USER]: " reply
        reply="${reply:-$NEW_USER}"
        valid_username "$reply" && break
        echo "Invalid username '$reply' (must match ^[a-z_][a-z0-9_-]*\$) — try again." >&2
    done
    NEW_USER="$reply"

    while [[ -z "$SSH_PUBKEY" ]] || ! valid_pubkey "$SSH_PUBKEY"; do
        [[ -n "$SSH_PUBKEY" ]] && echo "That doesn't look like a valid SSH public key line — try again." >&2
        read -r -p "Public key for $NEW_USER (paste the full 'ssh-ed25519 AAAA...' line): " SSH_PUBKEY
    done
}

# adduser --disabled-password leaves this account with no valid password at
# all (SSH-key-only login by design), so PAM's password check can never
# succeed — without this, `sudo` is unusable for this user in any context,
# interactive or scripted. Grant it explicitly instead, scoped to a single
# sudoers.d drop-in (not a blanket group policy change).
grant_passwordless_sudo() {
    local sudoers_file="/etc/sudoers.d/$NEW_USER"
    local tmp
    tmp=$(mktemp)
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >"$tmp"
    if ! visudo -cf "$tmp" &>/dev/null; then
        echo "Error: generated sudoers entry for $NEW_USER failed validation" >&2
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
    echo ""
    echo "Before continuing to ssh-harden.sh: open a NEW terminal and confirm you can log in as:"
    echo "  ssh $NEW_USER@<this-server-ip>"
    echo "using the public key you just provided."
}

main "$@"
