#!/usr/bin/env bash
# Configures the host firewall: deny incoming by default and allow OpenSSH.
set -euo pipefail

EXTRA_FIREWALL_PORTS="${EXTRA_FIREWALL_PORTS:-}"
require_root() { [[ "$(id -u)" -eq 0 ]] || {
    echo 'must run as root' >&2
    exit 1
}; }
non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }
valid_firewall_port() { [[ "$1" =~ ^[0-9]+(:[0-9]+)?(/(tcp|udp))?$ ]]; }

prompt_inputs() {
    non_interactive || read -r -p "Extra firewall ports to allow, space-separated (blank = SSH only): " EXTRA_FIREWALL_PORTS
}

main() {
    require_root
    prompt_inputs
    command -v ufw >/dev/null 2>&1 || {
        apt-get update -qq
        apt-get install -y -qq ufw
    }
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow OpenSSH
    local ports=()
    read -ra ports <<<"$EXTRA_FIREWALL_PORTS"
    for port in "${ports[@]}"; do
        valid_firewall_port "$port" || {
            echo "Invalid firewall port: $port" >&2
            exit 1
        }
        ufw allow "$port"
    done
    ufw --force enable
    ufw status verbose
}

main "$@"
