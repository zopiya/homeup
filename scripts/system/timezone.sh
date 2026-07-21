#!/usr/bin/env bash
# Sets the system timezone. Independent of create-user.sh/ufw.sh/
# hostname.sh/ssh-harden.sh — run standalone, or compose with `just provision`
# (see scripts/justfile). Idempotent: safe to re-run.
set -euo pipefail

TIMEZONE="${TIMEZONE:-Asia/Shanghai}"

log() { echo "==> $*"; }

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "Error: must run as root (e.g. sudo bash timezone.sh)" >&2
        exit 1
    }
}

non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }

prompt_inputs() {
    non_interactive && return
    local reply
    read -r -p "Timezone [$TIMEZONE]: " reply
    TIMEZONE="${reply:-$TIMEZONE}"
}

configure_timezone() {
    timedatectl set-timezone "$TIMEZONE"
    log "Timezone set to $TIMEZONE"
}

main() {
    require_root
    prompt_inputs
    configure_timezone
}

main "$@"
