#!/usr/bin/env bash
# shellcheck shell=bash

homeup_arch() {
    case "$(uname -m)" in
    x86_64 | amd64) printf '%s\n' amd64 ;;
    *)
        printf 'Unsupported architecture: %s (only x86_64/amd64 is supported).\n' "$(uname -m)" >&2
        return 1
        ;;
    esac
}

homeup_os() {
    [[ -r /etc/os-release ]] || {
        echo 'Cannot identify operating system: /etc/os-release is missing.' >&2
        return 1
    }
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
    debian | ubuntu) printf '%s\n' "$ID" ;;
    *)
        printf 'Unsupported operating system: %s (only Debian and Ubuntu are supported).\n' "${PRETTY_NAME:-unknown}" >&2
        return 1
        ;;
    esac
}

# Canonical HOMEUP_BIN_DIR/HOMEUP_PREFIX/cache-dir defaults. Every layer
# sources this file, so these are the single place that defines "where
# things go" — no script should inline its own copy of these paths.
homeup_bin_dir() { printf '%s\n' "${HOMEUP_BIN_DIR:-$HOME/.local/bin}"; }
homeup_cache_dir() { printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/homeup/downloads"; }

# Language-layer install location. HOMEUP_INSTALL_SCOPE=system is only used
# during image builds; containers/dev/Dockerfile passes HOMEUP_PREFIX and
# HOMEUP_BIN_DIR explicitly rather than relying on the system-scope
# defaults below, but its ENV PATH is a literal string that must still be
# kept in sync with whatever those two build args are set to.
homeup_language_prefix() {
    if [[ "${HOMEUP_INSTALL_SCOPE:-user}" == system ]]; then
        printf '%s\n' "${HOMEUP_PREFIX:-/usr/local/lib/homeup}"
    else
        printf '%s\n' "${HOMEUP_PREFIX:-$HOME/.local/opt/homeup}"
    fi
}

homeup_language_bin_dir() {
    if [[ "${HOMEUP_INSTALL_SCOPE:-user}" == system ]]; then
        printf '%s\n' "${HOMEUP_BIN_DIR:-/usr/local/bin}"
    else
        homeup_bin_dir
    fi
}

homeup_has_root() { [[ "$(id -u)" -eq 0 ]]; }
homeup_has_sudo() { ! homeup_has_root && command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; }
homeup_can_system_install() { homeup_has_root || homeup_has_sudo; }

homeup_as_root() {
    if homeup_has_root; then
        "$@"
    elif homeup_has_sudo; then
        sudo -n "$@"
    else
        echo 'System layer requires root or passwordless/non-interactive sudo.' >&2
        return 1
    fi
}

homeup_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

homeup_download() {
    local url="$1" expected="$2" destination="$3" actual
    curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 15 --retry 3 --output "$destination" "$url"
    actual="$(homeup_sha256 "$destination")"
    if [[ "$actual" != "$expected" ]]; then
        rm -f "$destination"
        printf 'Checksum mismatch for %s\nexpected: %s\nactual:   %s\n' "$url" "$expected" "$actual" >&2
        return 1
    fi
}

homeup_link() {
    local source="$1" destination="$2"
    mkdir -p "$(dirname "$destination")"
    ln -sfn "$source" "$destination"
}
