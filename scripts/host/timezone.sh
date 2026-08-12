#!/usr/bin/env bash
# Sets the host timezone. The default is retained for the owner's environment.
set -euo pipefail

TIMEZONE="${TIMEZONE:-Asia/Shanghai}"
require_root() { [[ "$(id -u)" -eq 0 ]] || {
    echo 'must run as root' >&2
    exit 1
}; }
non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }

main() {
    require_root
    if ! non_interactive; then
        local reply
        read -r -p "Timezone [$TIMEZONE]: " reply
        TIMEZONE="${reply:-$TIMEZONE}"
    fi
    timedatectl set-timezone "$TIMEZONE"
}

main "$@"
