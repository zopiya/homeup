#!/usr/bin/env bash
# Sets the host hostname and its 127.0.1.1 entry when requested.
set -euo pipefail

NEW_HOSTNAME="${NEW_HOSTNAME:-}"
require_root() { [[ "$(id -u)" -eq 0 ]] || {
    echo 'must run as root' >&2
    exit 1
}; }
non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }

main() {
    require_root
    if ! non_interactive; then read -r -p "Hostname (blank = leave unchanged): " NEW_HOSTNAME; fi
    [[ -n "$NEW_HOSTNAME" ]] || {
        echo 'Hostname unchanged'
        return
    }
    hostnamectl set-hostname "$NEW_HOSTNAME"
    sed -i '/^127\.0\.1\.1/d' /etc/hosts
    printf '127.0.1.1\t%s\n' "$NEW_HOSTNAME" >>/etc/hosts
}

main "$@"
