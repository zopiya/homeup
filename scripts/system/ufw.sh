#!/usr/bin/env bash
# Installs and configures ufw: deny incoming by default, allow OpenSSH, plus
# any EXTRA_FIREWALL_PORTS. Independent of create-user.sh/hostname.sh/
# timezone.sh/ssh-harden.sh — run standalone, or compose with `just provision`
# (see scripts/justfile). Idempotent: safe to re-run.
set -euo pipefail

EXTRA_FIREWALL_PORTS="${EXTRA_FIREWALL_PORTS:-}"

log() { echo "==> $*"; }

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "Error: must run as root (e.g. sudo bash ufw.sh)" >&2
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
            echo "Error: invalid EXTRA_FIREWALL_PORTS entry '$port' (expected e.g. 8080, 8080/tcp, 60000:61000/udp)" >&2
            exit 1
        }
        ufw allow "$port"
    done

    ufw --force enable
    log "ufw enabled:"
    ufw status verbose
}

main() {
    require_root
    prompt_inputs
    configure_firewall
}

main "$@"
