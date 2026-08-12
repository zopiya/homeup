#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/toolchain/lock.sh"

printf '# Toolchain metadata review\n\n'
printf 'Generated from official upstream metadata after the updater refreshed exact URLs and SHA-256 values. Review the resulting lock before merging.\n\n'
printf '| Component | Locked | Official metadata |\n| --- | --- | --- |\n'
node_latest="$(curl -fsSL https://nodejs.org/dist/index.json | jq -r 'map(select(.lts != false))[0].version')"
bun_latest="$(curl -fsSL https://api.github.com/repos/oven-sh/bun/releases/latest | jq -r .tag_name)"
just_latest="$(curl -fsSL https://api.github.com/repos/casey/just/releases/latest | jq -r .tag_name)"
chezmoi_latest="$(curl -fsSL https://api.github.com/repos/twpayne/chezmoi/releases/latest | jq -r .tag_name)"
sheldon_latest="$(curl -fsSL https://api.github.com/repos/rossmacarthur/sheldon/releases/latest | jq -r .tag_name)"
rust_latest="$(curl -fsSL https://static.rust-lang.org/dist/channel-rust-stable.toml | awk '/^\[pkg\.rustc\]/{found=1; next} found && /^version =/ && !printed {match($0, /[0-9]+\.[0-9]+\.[0-9]+/); print substr($0, RSTART, RLENGTH); printed=1}')"
python_latest="$(curl -fsSL 'https://www.python.org/api/v2/downloads/release/?is_published=true' | jq -r '[.[] | select(.name | test("^Python 3\\.[0-9]+\\.[0-9]+$")) | select(.pre_release == false)] | sort_by(.release_date) | last.name | sub("^Python "; "")')"
printf '| Node.js | %s | %s |\n' "$(lock_version node)" "$node_latest"
printf '| Bun | %s | %s |\n' "$(lock_version bun)" "$bun_latest"
printf '| just | %s | %s |\n' "$(lock_version just)" "$just_latest"
printf '| chezmoi | %s | %s |\n' "$(lock_version chezmoi)" "$chezmoi_latest"
printf '| Sheldon | %s | %s |\n' "$(lock_version sheldon)" "$sheldon_latest"
printf '| Rust | %s | %s |\n' "$(lock_version rust)" "$rust_latest"
printf '| Python | %s | %s |\n' "$(lock_version python)" "$python_latest"
