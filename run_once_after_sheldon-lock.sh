#!/usr/bin/env bash
# Locks sheldon plugins right after chezmoi apply writes
# ~/.config/sheldon/plugins.toml. The run_once_after_ prefix guarantees this
# runs after that file exists — even on the very first `chezmoi apply` (the
# old `just setup`-based version ran before `apply` and silently skipped on
# a fresh machine because the file didn't exist yet).
set -euo pipefail

if command -v sheldon &>/dev/null && [[ -f "$HOME/.config/sheldon/plugins.toml" ]]; then
    sheldon lock 2>/dev/null || true
    echo "Sheldon plugins locked"
fi
