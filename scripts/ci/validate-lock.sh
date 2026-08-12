#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/toolchain/lock.sh"

for component in $(lock_components); do
    version="$(lock_version "$component")"
    [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]] || {
        echo "Invalid version for $component: $version" >&2
        exit 1
    }
    [[ -n "$(lock_destination "$component")" ]] || {
        echo "Missing destination for $component" >&2
        exit 1
    }
    [[ -n "$(lock_install_components "$component")" ]] || {
        echo "Missing install components for $component" >&2
        exit 1
    }
    for arch in amd64 arm64; do
        url="$(lock_url "$component" "$arch")"
        checksum="$(lock_sha256 "$component" "$arch")"
        [[ "$url" == https://* ]] || {
            echo "$component/$arch URL is not HTTPS" >&2
            exit 1
        }
        [[ "$url" != *latest* ]] || {
            echo "$component/$arch URL must not use latest" >&2
            exit 1
        }
        [[ "$checksum" =~ ^[a-f0-9]{64}$ ]] || {
            echo "Invalid SHA-256 for $component/$arch" >&2
            exit 1
        }
    done
done

[[ "$(lock_tpm_repository)" == https://* ]] || {
    echo 'TPM repository must use HTTPS.' >&2
    exit 1
}
[[ "$(lock_tpm_revision)" =~ ^[a-f0-9]{40}$ ]] || {
    echo 'Invalid TPM revision.' >&2
    exit 1
}
