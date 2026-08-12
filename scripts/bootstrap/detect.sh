#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap/lib.sh"

carrier='host'
[[ -f /.dockerenv || -f /run/.containerenv ]] && carrier='container'
[[ -n "${CODESPACES:-}" ]] && carrier='codespaces'

os="$(homeup_os)"
printf 'carrier=%s\n' "$carrier"
printf 'os=%s\n' "$os"
printf 'architecture=%s\n' "$(homeup_arch)"
if homeup_has_root; then
    privilege=root
elif homeup_has_sudo; then
    privilege=sudo
else
    privilege=user
fi
printf 'privilege=%s\n' "$privilege"
