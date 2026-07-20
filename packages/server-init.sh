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

# No controlling terminal (e.g. invoked via `curl | bash` or cascaded from
# root-install.sh) means no `read` prompt can ever be answered — fall back to
# NEW_USER/SSH_PUBKEY/etc. env vars entirely instead of hanging on stdin.
# NONINTERACTIVE=1 forces the same path even from a real terminal.
non_interactive() { [[ ! -t 0 || "${NONINTERACTIVE:-}" == "1" ]]; }

# Mirrors the username regex justfile's _setup-shell already validates against,
# so both entry points reject the same malformed input the same way.
valid_username() { [[ "$1" =~ ^[a-z_][a-z0-9_-]*$ ]]; }

# Loose but useful: catches pasted garbage (comments, private keys, truncated
# lines) before it lands in authorized_keys, without re-implementing a full
# SSH key-format parser.
valid_pubkey() { [[ "$1" =~ ^(ssh-ed25519|ssh-rsa|ssh-dss|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh\.com|sk-ecdsa-sha2-nistp256@openssh\.com)\ [A-Za-z0-9+/]+=*([[:space:]].*)?$ ]]; }

valid_firewall_port() { [[ "$1" =~ ^[0-9]+(:[0-9]+)?(/(tcp|udp))?$ ]]; }

prompt_inputs() {
    if non_interactive; then
        valid_username "$NEW_USER" || {
            echo "Error: NEW_USER='$NEW_USER' is invalid (must match ^[a-z_][a-z0-9_-]*\$)." >&2
            exit 1
        }
        valid_pubkey "$SSH_PUBKEY" || {
            echo "Error: SSH_PUBKEY is required and must be a valid public key line when running non-interactively." >&2
            echo "Example: SSH_PUBKEY='ssh-ed25519 AAAA...' sudo -E bash packages/server-init.sh" >&2
            exit 1
        }
        return
    fi

    local reply
    while true; do
        read -r -p "New non-root username [$NEW_USER]: " reply
        reply="${reply:-$NEW_USER}"
        valid_username "$reply" && break
        echo "Invalid username '$reply' (must match ^[a-z_][a-z0-9_-]*\$) — try again." >&2
    done
    NEW_USER="$reply"

    while [[ -z "$SSH_PUBKEY" ]] || ! valid_pubkey "$SSH_PUBKEY"; do
        [[ -n "$SSH_PUBKEY" ]] && echo "That doesn't look like a valid SSH public key line — try again." >&2
        read -r -p "Public key for $NEW_USER (paste the full 'ssh-ed25519 AAAA...' line): " SSH_PUBKEY
    done

    read -r -p "Hostname (blank = leave unchanged): " NEW_HOSTNAME

    read -r -p "Timezone [$TIMEZONE]: " reply
    TIMEZONE="${reply:-$TIMEZONE}"

    read -r -p "Extra firewall ports to allow, space-separated (blank = SSH only): " EXTRA_FIREWALL_PORTS
}

# adduser --disabled-password leaves this account with no valid password at
# all (SSH-key-only login by design), so PAM's password check can never
# succeed — without this, `sudo` is unusable for this user in any context,
# interactive or scripted. Grant it explicitly instead, scoped to a single
# sudoers.d drop-in (not a blanket group policy change).
grant_passwordless_sudo() {
    local sudoers_file="/etc/sudoers.d/$NEW_USER"
    local tmp
    tmp=$(mktemp)
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >"$tmp"
    if ! visudo -cf "$tmp" &>/dev/null; then
        echo "Error: generated sudoers entry for $NEW_USER failed validation" >&2
        rm -f "$tmp"
        exit 1
    fi
    install -m 440 -o root -g root "$tmp" "$sudoers_file"
    rm -f "$tmp"
    echo "Passwordless sudo granted to $NEW_USER"
}

create_user() {
    if id "$NEW_USER" &>/dev/null; then
        echo "User $NEW_USER already exists, skipping creation"
    else
        adduser --disabled-password --gecos "" "$NEW_USER"
        usermod -aG sudo "$NEW_USER"
        echo "Created user $NEW_USER (sudo group)"
    fi

    grant_passwordless_sudo

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
        valid_firewall_port "$port" || {
            echo "Error: invalid EXTRA_FIREWALL_PORTS entry '$port' (expected e.g. 8080, 8080/tcp, 60000:61000/udp)" >&2
            exit 1
        }
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

    if non_interactive; then
        echo ""
        echo "Non-interactive mode: creating user '$NEW_USER' and configuring firewall/hostname/timezone."
    else
        echo ""
        echo "About to: create user '$NEW_USER', install your public key, set hostname/timezone,"
        echo "and open the firewall for SSH (+ any extra ports). This part is safe to re-run."
        read -r -p "Continue? [y/N] " reply
        [[ "$reply" =~ ^[Yy]$ ]] || {
            echo "Aborted"
            exit 0
        }
    fi

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

    # SSH hardening disables root/password login — the one genuinely irreversible
    # step here (a wrong key means a full lockout, recoverable only via
    # out-of-band console access). It never runs unattended, no matter how this
    # script was invoked; it always needs a human confirming the new login works.
    if non_interactive; then
        echo "SSH hardening was NOT applied automatically — it's never done unattended."
        echo "Once you've verified the login above works, harden it yourself by re-running"
        echo "this script interactively and typing 'yes' when asked:"
        echo "  sudo bash $0"
        return
    fi

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
