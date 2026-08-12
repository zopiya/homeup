#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap/lib.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/toolchain/lock.sh"

arch="$(homeup_arch)"
bin_dir="${HOMEUP_BIN_DIR:-$HOME/.local/bin}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/homeup/downloads"
mkdir -p "$bin_dir" "$cache_dir"

install_cli() {
    local component="$1" binary="$2" archive extracted found
    if command -v "$binary" >/dev/null 2>&1 && "$binary" --version 2>&1 | head -n 1 | grep -Fq "$(lock_version "$component")"; then
        return
    fi
    archive="$cache_dir/$component-$(lock_version "$component")-$arch.tar.gz"
    homeup_download "$(lock_url "$component" "$arch")" "$(lock_sha256 "$component" "$arch")" "$archive"
    extracted="$(mktemp -d)"
    trap 'rm -rf "$extracted"' RETURN
    tar -xzf "$archive" -C "$extracted"
    found="$(find "$extracted" -type f -name "$binary" -perm -u+x -print -quit)"
    [[ -n "$found" ]] || {
        echo "Could not find $binary in locked $component archive." >&2
        return 1
    }
    install -m 0755 "$found" "$bin_dir/$binary"
    trap - RETURN
    rm -rf "$extracted"
}

install_cli just just
install_cli chezmoi chezmoi
install_cli sheldon sheldon
