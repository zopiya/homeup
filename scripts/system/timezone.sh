#!/usr/bin/env bash
# Sets the system timezone. Independent of create-user.sh/ufw.sh/
# hostname.sh/ssh-harden.sh — run standalone, or compose with `just provision`
# (see scripts/justfile). Idempotent: safe to re-run.
set -euo pipefail

TIMEZONE="${TIMEZONE:-Asia/Shanghai}"

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
        error "must run as root (e.g. sudo bash timezone.sh)"
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
    success "Timezone set to $TIMEZONE"
}

main() {
    require_root
    prompt_inputs
    configure_timezone
}

main "$@"
