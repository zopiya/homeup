#!/usr/bin/env bash
# Disables root/password SSH login. The one genuinely irreversible step in
# this repo's server provisioning (a wrong key means a full lockout,
# recoverable only via out-of-band console access) — so unlike the other
# scripts/system/*.sh scripts, this one NEVER runs unattended and is never
# composed into an automatic "run everything" recipe. It's always a separate,
# deliberate command you run yourself, after confirming from a SEPARATE
# session that you can log in as your new sudo user. See scripts/justfile's
# `ssh-harden` recipe (or scripts/init.sh's printed instructions) — nothing
# else calls this script for you.
set -euo pipefail

NEW_USER="${NEW_USER:-your new user}"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_RESET=$'\033[0m'
else
    C_GREEN=''
    C_YELLOW=''
    C_RED=''
    C_RESET=''
fi
log() { echo "==> $*"; }
success() { echo "${C_GREEN}✓${C_RESET} $*"; }
warn() { echo "${C_YELLOW}⚠${C_RESET} $*" >&2; }
error() { echo "${C_RED}✗${C_RESET} $*" >&2; }

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        error "must run as root (e.g. sudo bash ssh-harden.sh)"
        exit 1
    }
}

require_tty() {
    [[ -t 0 ]] || {
        error "SSH hardening is never run unattended — refusing to run without a controlling terminal."
        echo "  Re-run this interactively." >&2
        exit 1
    }
}

harden_ssh() {
    local sshd_config="/etc/ssh/sshd_config"
    cp "$sshd_config" "${sshd_config}.bak.$(date +%s)"
    sed -i \
        -e 's/^#*PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' \
        "$sshd_config"
    systemctl restart sshd
    success "sshd hardened: root login and password auth disabled"
}

main() {
    require_root
    require_tty

    warn "This is irreversible without out-of-band console access — read carefully."
    echo "Before continuing: confirm from a SEPARATE terminal that you can log in as:"
    echo "  ssh $NEW_USER@<this-server-ip>"
    echo "Do NOT continue until that works — this disables root and password SSH login."
    echo ""
    read -r -p "Did the new login succeed? Type 'yes' to disable root/password SSH login: " confirm
    if [[ "$confirm" == "yes" ]]; then
        harden_ssh
        echo "${C_GREEN}=== Done. root/password SSH login is now disabled. ===${C_RESET}"
    else
        warn "Skipped SSH hardening — root/password login are still enabled."
        echo "Re-run this script (it's idempotent) once you've verified the new user can log in."
    fi
}

main "$@"
