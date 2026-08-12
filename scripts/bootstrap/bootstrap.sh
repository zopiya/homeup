#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap/lib.sh"

mode="${1:-auto}"
case "$mode" in auto | full | user) ;; *)
    echo "Unknown bootstrap mode: $mode (use auto, full, or user)." >&2
    exit 2
    ;;
esac
homeup_os >/dev/null

case "$mode" in
full)
    homeup_can_system_install || {
        echo 'bootstrap full requires root or passwordless/non-interactive sudo.' >&2
        exit 1
    }
    "$ROOT_DIR/scripts/bootstrap/system.sh"
    ;;
auto)
    if homeup_can_system_install; then
        "$ROOT_DIR/scripts/bootstrap/system.sh"
    else
        echo 'System layer skipped: no root or passwordless/non-interactive sudo.' >&2
    fi
    ;;
user) ;;
esac

"$ROOT_DIR/scripts/bootstrap/language.sh"
"$ROOT_DIR/scripts/bootstrap/user.sh"
