#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap/lib.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/toolchain/lock.sh"

arch="$(homeup_arch)"
if [[ "${HOMEUP_INSTALL_SCOPE:-user}" == system ]]; then
    prefix="${HOMEUP_PREFIX:-/usr/local/lib/homeup}"
    bin_dir="${HOMEUP_BIN_DIR:-/usr/local/bin}"
else
    prefix="${HOMEUP_PREFIX:-$HOME/.local/opt/homeup}"
    bin_dir="${HOMEUP_BIN_DIR:-$HOME/.local/bin}"
fi
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/homeup/downloads"
mkdir -p "$prefix" "$bin_dir" "$cache_dir"

artifact() {
    local component="$1" output="$2"
    homeup_download "$(lock_url "$component" "$arch")" "$(lock_sha256 "$component" "$arch")" "$output"
}

install_node() {
    local version archive target extracted command
    version="$(lock_version node)"
    target="$prefix/node-$version"
    [[ -x "$target/bin/node" ]] || {
        archive="$cache_dir/node-$version-$arch.tar.xz"
        artifact node "$archive"
        extracted="$(mktemp -d)"
        trap 'rm -rf "$extracted"' RETURN
        tar -xJf "$archive" -C "$extracted"
        rm -rf "$target"
        mv "$extracted"/node-v*-linux-* "$target"
        trap - RETURN
        rm -rf "$extracted"
    }
    for command in node npm npx corepack; do
        homeup_link "$target/bin/$command" "$bin_dir/$command"
    done
}

install_bun() {
    local version archive target extracted
    version="$(lock_version bun)"
    target="$prefix/bun-$version"
    [[ -x "$target/bun" ]] || {
        archive="$cache_dir/bun-$version-$arch.zip"
        artifact bun "$archive"
        extracted="$(mktemp -d)"
        trap 'rm -rf "$extracted"' RETURN
        unzip -q "$archive" -d "$extracted"
        rm -rf "$target"
        mkdir -p "$target"
        mv "$extracted"/bun-linux-*/bun "$target/bun"
        chmod +x "$target/bun"
        trap - RETURN
        rm -rf "$extracted"
    }
    homeup_link "$target/bun" "$bin_dir/bun"
}

install_python() {
    local version archive target extracted
    version="$(lock_version python)"
    target="$prefix/python-$version"
    [[ -x "$target/bin/python3" ]] || {
        archive="$cache_dir/python-$version-$arch.tar.gz"
        artifact python "$archive"
        extracted="$(mktemp -d)"
        trap 'rm -rf "$extracted"' RETURN
        tar -xzf "$archive" -C "$extracted"
        rm -rf "$target"
        mv "$extracted/python" "$target"
        trap - RETURN
        rm -rf "$extracted"
    }
    homeup_link "$target/bin/python3" "$bin_dir/python3"
    homeup_link "$target/bin/python3" "$bin_dir/python"
    homeup_link "$target/bin/pip3" "$bin_dir/pip3"
    homeup_link "$target/bin/pip3" "$bin_dir/pip"
}

install_rust() {
    local version archive target extracted command installer
    local -a installers
    version="$(lock_version rust)"
    target="$prefix/rust-$version"
    [[ -x "$target/bin/rustc" ]] || {
        archive="$cache_dir/rust-$version-$arch.tar.xz"
        artifact rust "$archive"
        extracted="$(mktemp -d)"
        trap 'rm -rf "$extracted"' RETURN
        tar -xJf "$archive" -C "$extracted"
        rm -rf "$target"
        installers=("$extracted"/rust-"$version"-*/install.sh)
        installer="${installers[0]}"
        [[ -x "$installer" ]] || {
            echo 'Rust archive does not contain install.sh.' >&2
            return 1
        }
        "$installer" --prefix="$target" --disable-ldconfig
        trap - RETURN
        rm -rf "$extracted"
    }
    for command in cargo rustc rustdoc rustfmt clippy-driver; do
        [[ -x "$target/bin/$command" ]] && homeup_link "$target/bin/$command" "$bin_dir/$command"
    done
}

homeup_os >/dev/null
install_node
install_bun
install_python
install_rust
printf 'Language layer installed to %s.\n' "$prefix"
