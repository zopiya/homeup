#!/usr/bin/env bash
# Installs and configures ufw: deny incoming by default, allow OpenSSH, plus
# any EXTRA_FIREWALL_PORTS. Independent of create-user.sh/hostname.sh/
# timezone.sh/ssh-harden.sh — run standalone, or compose with `just provision`
# (see scripts/justfile). Idempotent: safe to re-run.
set -euo pipefail

EXTRA_FIREWALL_PORTS="${EXTRA_FIREWALL_PORTS:-}"

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
        error "must run as root (e.g. sudo bash ufw.sh)"
        exit 1
    }
}

non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }

valid_firewall_port() { [[ "$1" =~ ^[0-9]+(:[0-9]+)?(/(tcp|udp))?$ ]]; }

prompt_inputs() {
    non_interactive && return
    read -r -p "Extra firewall ports to allow, space-separated (blank = SSH only): " EXTRA_FIREWALL_PORTS
}

configure_firewall() {
    apt-get update -qq
    apt-get install -y -qq ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow OpenSSH

    local extra_ports=()
    read -ra extra_ports <<<"$EXTRA_FIREWALL_PORTS"
    for port in "${extra_ports[@]}"; do
        valid_firewall_port "$port" || {
            error "invalid EXTRA_FIREWALL_PORTS entry '$port' (expected e.g. 8080, 8080/tcp, 60000:61000/udp)"
            exit 1
        }
        ufw allow "$port"
    done

    ufw --force enable
    success "ufw enabled"
    ufw status verbose
}

main() {
    require_root
    prompt_inputs
    configure_firewall
}

main "$@"
