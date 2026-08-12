#!/usr/bin/env bash
# Thin curl entry point: it only maintains a checkout and delegates all setup
# to the checked-in, locked bootstrap implementation.
set -euo pipefail

repo_url="${HOMEUP_REPO_URL:-https://github.com/zopiya/homeup.git}"
repo_dir="${HOMEUP_DIR:-$HOME/.local/share/homeup-linux}"

command -v git >/dev/null 2>&1 || {
    echo 'git is required to bootstrap. Run the system layer first or install git from apt.' >&2
    exit 1
}
if [[ -d "$repo_dir/.git" ]]; then
    git -C "$repo_dir" pull --ff-only
else
    mkdir -p "$(dirname "$repo_dir")"
    git clone "$repo_url" "$repo_dir"
fi
just_bin="$(bash "$repo_dir/scripts/bootstrap/bootstrap-just.sh")"
exec "$just_bin" --justfile "$repo_dir/justfile" bootstrap auto
