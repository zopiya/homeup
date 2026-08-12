#!/usr/bin/env bash
# Thin curl entry point: it only maintains a checkout and delegates all setup
# to the checked-in, locked bootstrap implementation. Git is deliberately not
# a prerequisite: a minimal Debian/Ubuntu image can start from curl and tar.
set -euo pipefail

repo_url="${HOMEUP_REPO_URL:-https://github.com/zopiya/homeup.git}"
repo_dir="${HOMEUP_DIR:-$HOME/.local/share/homeup}"
repo_ref="${HOMEUP_REF:-main}"
if [[ -n "${HOMEUP_ARCHIVE_URL:-}" ]]; then
    archive_url="$HOMEUP_ARCHIVE_URL"
elif [[ "$repo_url" == https://github.com/* ]]; then
    archive_repository="${repo_url#https://github.com/}"
    archive_repository="${archive_repository%.git}"
    archive_url="https://github.com/$archive_repository/archive/refs/heads/$repo_ref.tar.gz"
else
    echo 'HOMEUP_ARCHIVE_URL is required without Git when HOMEUP_REPO_URL is not a GitHub HTTPS URL.' >&2
    exit 2
fi

install_archive_checkout() {
    local temporary archive extracted
    temporary="$(mktemp -d)"
    trap 'rm -rf "$temporary"' RETURN
    archive="$temporary/homeup.tar.gz"
    curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 15 --retry 3 --output "$archive" "$archive_url"
    tar -xzf "$archive" -C "$temporary"
    extracted="$(find "$temporary" -mindepth 1 -maxdepth 1 -type d -print -quit)"
    [[ -n "$extracted" && -f "$extracted/scripts/bootstrap/bootstrap-just.sh" ]] || {
        echo 'Downloaded archive is not a Homeup checkout.' >&2
        return 1
    }
    if [[ -e "$repo_dir" ]]; then
        [[ -f "$repo_dir/.homeup-archive-checkout" ]] || {
            echo "Refusing to replace unmanaged directory: $repo_dir" >&2
            return 1
        }
        rm -rf "$repo_dir"
    fi
    mkdir -p "$(dirname "$repo_dir")"
    mv "$extracted" "$repo_dir"
    : >"$repo_dir/.homeup-archive-checkout"
    trap - RETURN
    rm -rf "$temporary"
}

if [[ -d "$repo_dir/.git" ]]; then
    git -C "$repo_dir" pull --ff-only
elif command -v git >/dev/null 2>&1; then
    if [[ -e "$repo_dir" ]]; then
        [[ -f "$repo_dir/.homeup-archive-checkout" ]] || {
            echo "Refusing to replace unmanaged directory: $repo_dir" >&2
            exit 1
        }
        rm -rf "$repo_dir"
    fi
    mkdir -p "$(dirname "$repo_dir")"
    git clone --depth 1 --branch "$repo_ref" "$repo_url" "$repo_dir"
else
    install_archive_checkout
fi
just_bin="$(bash "$repo_dir/scripts/bootstrap/bootstrap-just.sh")"
exec "$just_bin" --justfile "$repo_dir/justfile" bootstrap auto
