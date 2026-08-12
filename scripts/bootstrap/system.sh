#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap/lib.sh"

homeup_os >/dev/null
homeup_as_root apt-get update -qq
mapfile -t packages < <(awk '!/^($|#)/ {print $1}' "$ROOT_DIR/packages/base.apt")
homeup_as_root apt-get install -y --no-install-recommends "${packages[@]}"
