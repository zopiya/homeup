set shell := ["bash", "-uc"]
set dotenv-load := true

mod scripts 'scripts/justfile'
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

# Compatibility aliases retained during the v1 migration.
provision: host::provision

install: system::install language::install

setup:
    @echo "setup is deprecated: shell changes are host-only and are no longer made automatically."

apply: user::apply

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

upgrade:
    @echo "Use your normal apt upgrade policy. Locked artifacts change only through a reviewed lock update."

clean:
    @echo "No global cache cleanup is performed by v1."
