#!/usr/bin/env bash
# Sets the hostname (and matching /etc/hosts entry). Independent of
# create-user.sh/ufw.sh/timezone.sh/ssh-harden.sh — run standalone, or
# compose with `just provision` (see scripts/justfile). Idempotent: safe to
# re-run.
set -euo pipefail

NEW_HOSTNAME="${NEW_HOSTNAME:-}"

log() { echo "==> $*"; }

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "Error: must run as root (e.g. sudo bash hostname.sh)" >&2
        exit 1
    }
}

non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }

prompt_inputs() {
    non_interactive && return
    read -r -p "Hostname (blank = leave unchanged): " NEW_HOSTNAME
}

configure_hostname() {
    if [[ -z "$NEW_HOSTNAME" ]]; then
        log "Hostname unchanged"
        return
    fi
    hostnamectl set-hostname "$NEW_HOSTNAME"
    sed -i '/^127\.0\.1\.1/d' /etc/hosts
    printf '127.0.1.1\t%s\n' "$NEW_HOSTNAME" >>/etc/hosts
    log "Hostname set to $NEW_HOSTNAME"
}

main() {
    require_root
    prompt_inputs
    configure_hostname
}

main "$@"
