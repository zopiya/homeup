#!/usr/bin/env bash
# Day 0 server provisioning — run once, as root, on a fresh Debian/Ubuntu cloud server,
# BEFORE the Day 1 chezmoi/just dotfiles bootstrap (which runs as the new user).
#
# Creates a sudo user with key-only login, sets hostname/timezone, opens ufw for SSH,
# then (only after you've verified the new login works) disables root/password SSH login.
set -euo pipefail

NEW_USER="${NEW_USER:-zopiya}"
SSH_PUBKEY="${SSH_PUBKEY:-}"
NEW_HOSTNAME="${NEW_HOSTNAME:-}"
TIMEZONE="${TIMEZONE:-Asia/Shanghai}"
EXTRA_FIREWALL_PORTS="${EXTRA_FIREWALL_PORTS:-}"

require_root() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "Error: must run as root (e.g. sudo bash server-init.sh)" >&2
        exit 1
    }
}

prompt_inputs() {
    local reply
    read -r -p "New non-root username [$NEW_USER]: " reply
    NEW_USER="${reply:-$NEW_USER}"

    while [[ -z "$SSH_PUBKEY" ]]; do
        read -r -p "Public key for $NEW_USER (paste the full 'ssh-ed25519 AAAA...' line): " SSH_PUBKEY
    done

    read -r -p "Hostname (blank = leave unchanged): " NEW_HOSTNAME

    read -r -p "Timezone [$TIMEZONE]: " reply
    TIMEZONE="${reply:-$TIMEZONE}"

    read -r -p "Extra firewall ports to allow, space-separated (blank = SSH only): " EXTRA_FIREWALL_PORTS
}

create_user() {
    if id "$NEW_USER" &>/dev/null; then
        echo "User $NEW_USER already exists, skipping creation"
    else
        adduser --disabled-password --gecos "" "$NEW_USER"
        usermod -aG sudo "$NEW_USER"
        echo "Created user $NEW_USER (sudo group)"
    fi

    local ssh_dir="/home/$NEW_USER/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"
    install -d -m 700 -o "$NEW_USER" -g "$NEW_USER" "$ssh_dir"
    touch "$auth_keys"
    grep -qxF "$SSH_PUBKEY" "$auth_keys" || echo "$SSH_PUBKEY" >>"$auth_keys"
    chmod 600 "$auth_keys"
    chown "$NEW_USER:$NEW_USER" "$auth_keys"
    echo "Public key installed for $NEW_USER"
}

configure_hostname() {
    if [[ -z "$NEW_HOSTNAME" ]]; then
        echo "Hostname unchanged"
        return
    fi
    hostnamectl set-hostname "$NEW_HOSTNAME"
    sed -i '/^127\.0\.1\.1/d' /etc/hosts
    printf '127.0.1.1\t%s\n' "$NEW_HOSTNAME" >>/etc/hosts
    echo "Hostname set to $NEW_HOSTNAME"
}

configure_timezone() {
    timedatectl set-timezone "$TIMEZONE"
    echo "Timezone set to $TIMEZONE"
}

configure_firewall() {
    apt-get update -qq
    apt-get install -y -qq ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow OpenSSH

    local extra_ports=()
    read -ra extra_ports <<<"$EXTRA_FIREWALL_PORTS"
    for port in "${extra_ports[@]}"; do
        ufw allow "$port"
    done

    ufw --force enable
    echo "ufw enabled:"
    ufw status verbose
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
    echo "sshd hardened: root login and password auth disabled"
}

main() {
    require_root
    echo "=== homeup-linux Day 0 server provisioning ==="
    prompt_inputs

    echo ""
    echo "About to: create user '$NEW_USER', install your public key, set hostname/timezone,"
    echo "and open the firewall for SSH (+ any extra ports). This part is safe to re-run."
    read -r -p "Continue? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || {
        echo "Aborted"
        exit 0
    }

    create_user
    configure_hostname
    configure_timezone
    configure_firewall

    echo ""
    echo "=== Step 1 complete ==="
    echo "Before continuing: open a NEW terminal and confirm you can log in as:"
    echo "  ssh $NEW_USER@<this-server-ip>"
    echo "using the public key you just provided. Do NOT close this session until that works —"
    echo "the next step disables root and password SSH login."
    echo ""
    read -r -p "Did the new login succeed? Type 'yes' to disable root/password SSH login: " confirm
    if [[ "$confirm" == "yes" ]]; then
        harden_ssh
        echo "=== Done. root/password SSH login is now disabled. ==="
    else
        echo "Skipped SSH hardening — root/password login are still enabled."
        echo "Re-run this script (it's idempotent) once you've verified the new user can log in."
    fi
}

main "$@"
