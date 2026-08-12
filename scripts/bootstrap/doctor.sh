#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap/lib.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/toolchain/lock.sh"

export PATH="${HOMEUP_BIN_DIR:-$HOME/.local/bin}:$PATH"
"$ROOT_DIR/scripts/bootstrap/detect.sh"
failures=0
check_version() {
    local component="$1" command="$2" expected="$3" actual
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'missing  %-9s expected %s\n' "$component" "$expected"
        failures=$((failures + 1))
        return
    fi
    actual="$($command --version 2>&1 | head -n 1)"
    if [[ "$actual" == *"$expected"* ]]; then
        printf 'ok       %-9s %s\n' "$component" "$actual"
    else
        printf 'mismatch %-9s expected %s, got %s\n' "$component" "$expected" "$actual"
        failures=$((failures + 1))
    fi
}

check_version just just "$(lock_version just)"
check_version chezmoi chezmoi "$(lock_version chezmoi)"
check_version sheldon sheldon "$(lock_version sheldon)"
check_version node node "v$(lock_version node)"
check_version bun bun "$(lock_version bun)"
check_version python python3 "$(lock_version python)"
check_version rust rustc "$(lock_version rust)"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ "$(git -C "$TPM_DIR" rev-parse HEAD 2>/dev/null || true)" == "$(lock_tpm_revision)" ]]; then
    printf 'ok       %-9s %s\n' tpm "$(lock_tpm_revision)"
else
    printf 'missing  %-9s expected %s\n' tpm "$(lock_tpm_revision)"
    failures=$((failures + 1))
fi
if ((failures)); then exit 1; fi
