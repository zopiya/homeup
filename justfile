set shell := ["bash", "-uc"]
set dotenv-load := true

mod system 'just/system.just'
mod language 'just/language.just'
mod user 'just/user.just'
mod host 'just/host.just'

ROOT := justfile_directory()

default:
    @just --list

# Apply every layer permitted by the current privilege level.
bootstrap mode="auto":
    bash "{{ROOT}}/scripts/bootstrap/bootstrap.sh" "{{mode}}"

# Report carrier detection and exact locked runtime/CLI versions.
doctor:
    bash "{{ROOT}}/scripts/bootstrap/doctor.sh"

diff:
    chezmoi diff

update:
    chezmoi update

validate:
    chezmoi init --source "{{ROOT}}" --destination /tmp/homeup-chezmoi-validate --dry-run

lint:
    #!/usr/bin/env bash
    set -euo pipefail
    while IFS= read -r -d '' file; do shellcheck "$file"; done < <(find . -name '*.sh' -type f ! -path './.git/*' -print0)
    while IFS= read -r -d '' file; do bash -n "$file"; done < <(find . -name '*.sh' -type f ! -path './.git/*' -print0)
    while IFS= read -r -d '' file; do zsh -n "$file"; done < <(find . -name '*.zsh' -type f ! -path './.git/*' -print0)

fmt:
    shfmt -w -i 4 $(find . -name '*.sh' -type f ! -path './.git/*')
