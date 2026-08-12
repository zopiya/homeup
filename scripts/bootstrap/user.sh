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
if [[ ! -d "$TPM_DIR/.git" ]] || [[ "$(git -C "$TPM_DIR" rev-parse HEAD 2>/dev/null || true)" != "$TPM_REVISION" ]]; then
    rm -rf "$TPM_DIR"
    mkdir -p "$(dirname "$TPM_DIR")"
    git init -q "$TPM_DIR"
    git -C "$TPM_DIR" remote add origin "$TPM_REPOSITORY"
    git -C "$TPM_DIR" fetch -q --depth 1 origin "$TPM_REVISION"
    git -C "$TPM_DIR" checkout -q --detach FETCH_HEAD
fi
printf 'User layer applied from %s.\n' "$ROOT_DIR"
