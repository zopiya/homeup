#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap/lib.sh"
bin_dir="${HOMEUP_BIN_DIR:-$HOME/.local/bin}"
"$ROOT_DIR/scripts/bootstrap/core-cli.sh"
export PATH="$bin_dir:$PATH"
chezmoi init --source "$ROOT_DIR" --apply
TPM_DIR="$HOME/.tmux/plugins/tpm"
TPM_REPOSITORY="$(
    source "$ROOT_DIR/toolchain/lock.sh"
    lock_tpm_repository
)"
TPM_REVISION="$(
    source "$ROOT_DIR/toolchain/lock.sh"
    lock_tpm_revision
)"
install_tpm_archive() {
    local temporary archive extracted
    temporary="$(mktemp -d)"
    trap 'rm -rf "$temporary"' RETURN
    archive="$temporary/tpm.tar.gz"
    homeup_download "$(lock_tpm_url)" "$(lock_tpm_sha256)" "$archive"
    tar -xzf "$archive" -C "$temporary"
    extracted="$(find "$temporary" -mindepth 1 -maxdepth 1 -type d -name 'tpm-*' -print -quit)"
    [[ -n "$extracted" ]] || {
        echo 'TPM archive did not contain a directory.' >&2
        return 1
    }
    rm -rf "$TPM_DIR"
    mkdir -p "$(dirname "$TPM_DIR")"
    mv "$extracted" "$TPM_DIR"
    printf '%s\n' "$TPM_REVISION" >"$TPM_DIR/.homeup-archive-checkout"
    trap - RETURN
    rm -rf "$temporary"
}

if command -v git >/dev/null 2>&1 && { [[ ! -d "$TPM_DIR/.git" ]] || [[ "$(git -C "$TPM_DIR" rev-parse HEAD 2>/dev/null || true)" != "$TPM_REVISION" ]]; }; then
    rm -rf "$TPM_DIR"
    mkdir -p "$(dirname "$TPM_DIR")"
    git init -q "$TPM_DIR"
    git -C "$TPM_DIR" remote add origin "$TPM_REPOSITORY"
    git -C "$TPM_DIR" fetch -q --depth 1 origin "$TPM_REVISION"
    git -C "$TPM_DIR" checkout -q --detach FETCH_HEAD
elif ! command -v git >/dev/null 2>&1 && [[ "$(cat "$TPM_DIR/.homeup-archive-checkout" 2>/dev/null || true)" != "$TPM_REVISION" ]]; then
    install_tpm_archive
fi
printf 'User layer applied from %s.\n' "$ROOT_DIR"
