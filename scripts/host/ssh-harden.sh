#!/usr/bin/env bash
# The irreversible host-only SSH hardening step. It always needs a TTY and a
# literal confirmation, and is never called by bootstrap or provisioning.
set -euo pipefail

NEW_USER="${NEW_USER:-your new user}"

require_root() { [[ "$(id -u)" -eq 0 ]] || {
    echo 'must run as root' >&2
    exit 1
}; }
require_tty() { [[ -t 0 ]] || {
    echo 'SSH hardening refuses non-interactive execution.' >&2
    exit 1
}; }

main() {
    require_root
    require_tty
    echo "Verify a separate session can log in as: ssh $NEW_USER@<this-server-ip>"
    read -r -p "Type 'yes' to disable root and password SSH login: " confirm
    [[ "$confirm" == yes ]] || {
        echo 'SSH hardening skipped.'
        return
    }
    local sshd_config=/etc/ssh/sshd_config
    cp "$sshd_config" "${sshd_config}.bak.$(date +%s)"
    sed -i \
        -e 's/^#*PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' \
        "$sshd_config"
    systemctl restart sshd
    echo 'sshd hardened: root login and password authentication are disabled.'
}

main "$@"
