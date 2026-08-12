#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap/lib.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/toolchain/lock.sh"

bin_dir="${HOMEUP_BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$bin_dir"
if ! command -v just >/dev/null 2>&1 || [[ "$(just --version | awk '{print $2}')" != "$(lock_version just)" ]]; then
    HOMEUP_BIN_DIR="$bin_dir" "$ROOT_DIR/scripts/bootstrap/core-cli.sh"
fi
printf '%s\n' "$bin_dir/just"
