#!/usr/bin/env bash
# Day 1 tool installer — for CLI tools that apt either doesn't package or
# ships too old a version of (see scripts/packages/apt-packages.txt for the
# rest that come straight from apt). Installs everything into ~/.local/bin, which
# dot_config/zsh/path.zsh already puts first on PATH. Safe to re-run: each
# installer is skipped once the tool is already found on PATH.
#
# x86_64/amd64 only — check_arch() below fails fast on other architectures
# instead of silently installing binaries that won't execute. On arm64,
# adjust the release-asset patterns (grep for "aarch64"/"arm64" instead).
#
# The GitHub-release patterns here were written from memory of each project's
# current release-asset naming; they can drift when a project changes its
# release tooling. If install_from_github fails to find a match, check the
# project's actual "latest" release page and fix the pattern below.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# Shared timeout for every network call in this script so a stalled upstream
# (dead mirror, rate-limited API, hung TLS handshake) fails fast instead of
# hanging the whole install run.
CURL_OPTS=(--connect-timeout 10 --max-time 180)

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_BLUE=$'\033[34m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_RESET=$'\033[0m'
else
    C_BLUE=''
    C_GREEN=''
    C_YELLOW=''
    C_RED=''
    C_RESET=''
fi
log() { echo "${C_BLUE}==>${C_RESET} $*"; }
success() { echo "${C_GREEN}✓${C_RESET} $*"; }
warn() { echo "${C_YELLOW}⚠${C_RESET} $*" >&2; }
error() { echo "${C_RED}✗${C_RESET} $*" >&2; }
already_installed() { command -v "$1" &>/dev/null; }

check_arch() {
    local arch
    arch="$(uname -m)"
    if [[ "$arch" != "x86_64" ]]; then
        error "install-tools.sh only supports x86_64 (detected: $arch)."
        echo "  The GitHub-release patterns in this script are all amd64/x86_64 —" >&2
        echo "  on arm64, swap in aarch64/arm64 before running it." >&2
        exit 1
    fi
}

# Debian/Ubuntu package bat/fd-find as batcat/fdfind to avoid name clashes
# with unrelated packages. Symlink the names this config's aliases/exports
# expect (aliases.zsh's `cat="bat"`, exports.zsh's FZF_DEFAULT_COMMAND, etc).
link_apt_renamed_tools() {
    if ! already_installed bat && command -v batcat &>/dev/null; then
        ln -sf "$(command -v batcat)" "$BIN_DIR/bat"
        log "linked bat -> $(command -v batcat)"
    fi
    if ! already_installed fd && command -v fdfind &>/dev/null; then
        ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"
        log "linked fd -> $(command -v fdfind)"
    fi
}

# --- Generic GitHub-release installer -------------------------------------
# Downloads the newest release asset matching $pattern from $repo, and
# installs the binary named $bin (found anywhere inside the download) into
# $BIN_DIR. Handles both archives (tar.gz/tgz/tar.xz/zip) and bare binary assets.
install_from_github() {
    local bin="$1" repo="$2" pattern="$3"
    if already_installed "$bin"; then
        log "$bin already installed, skipping"
        return
    fi

    log "Installing $bin from $repo..."
    local url
    url=$(curl "${CURL_OPTS[@]}" -fsSL "https://api.github.com/repos/$repo/releases/latest" |
        grep -o '"browser_download_url": *"[^"]*"' |
        cut -d'"' -f4 |
        grep -iE "$pattern" | head -n1)
    if [[ -z "$url" ]]; then
        error "$bin: no release asset matching '$pattern' for $repo — skipping"
        return 1
    fi

    local tmp
    tmp=$(mktemp -d)
    # `trap ... RETURN` is registered globally, not scoped to this function —
    # left alone, it fires again on the *next* function return anywhere in the
    # script (with $tmp now out of scope, which is a nounset error). Reset it
    # as part of firing so cleanup only ever applies to this invocation.
    trap 'rm -rf "$tmp"; trap - RETURN' RETURN

    if ! curl "${CURL_OPTS[@]}" -fsSL "$url" -o "$tmp/asset"; then
        error "$bin: download failed: $url"
        return 1
    fi

    if ! {
        case "$url" in
        *.tar.gz | *.tgz) tar -xzf "$tmp/asset" -C "$tmp" ;;
        *.tar.xz) tar -xJf "$tmp/asset" -C "$tmp" ;;
        *.zip) (cd "$tmp" && unzip -q asset) ;;
        *) mv "$tmp/asset" "$tmp/$bin" ;;
        esac
    } then
        error "$bin: failed to extract asset from $url"
        return 1
    fi

    local found
    found=$(find "$tmp" -type f -iname "$bin" | head -n1)
    if [[ -z "$found" || ! -s "$found" ]]; then
        error "$bin: could not locate a non-empty '$bin' binary inside the downloaded asset"
        return 1
    fi
    install -m755 "$found" "$BIN_DIR/$bin"
    success "$bin -> $BIN_DIR/$bin"
}

# --- Official installer scripts (already support a custom bin dir) --------

install_chezmoi() {
    already_installed chezmoi && {
        log "chezmoi already installed, skipping"
        return
    }
    sh -c "$(curl "${CURL_OPTS[@]}" -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
    success "chezmoi installed"
}

install_just() {
    already_installed just && {
        log "just already installed, skipping"
        return
    }
    curl "${CURL_OPTS[@]}" --proto '=https' --tlsv1.2 -fsSL https://just.systems/install.sh | bash -s -- --to "$BIN_DIR"
    success "just installed"
}

install_starship() {
    already_installed starship && {
        log "starship already installed, skipping"
        return
    }
    curl "${CURL_OPTS[@]}" -sS https://starship.rs/install.sh | sh -s -- -y -b "$BIN_DIR"
    success "starship installed"
}

install_zoxide() {
    already_installed zoxide && {
        log "zoxide already installed, skipping"
        return
    }
    curl "${CURL_OPTS[@]}" -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$BIN_DIR"
    success "zoxide installed"
}

install_sheldon() {
    already_installed sheldon && {
        log "sheldon already installed, skipping"
        return
    }
    curl "${CURL_OPTS[@]}" --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --to "$BIN_DIR"
    success "sheldon installed"
}

install_uv() {
    already_installed uv && {
        log "uv already installed, skipping"
        return
    }
    curl "${CURL_OPTS[@]}" -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$BIN_DIR" sh
    success "uv installed"
}

install_bun() {
    already_installed bun && {
        log "bun already installed, skipping"
        return
    }
    # BUN_INSTALL=~/.local makes the installer place the binary at ~/.local/bin/bun.
    # It may also append PATH lines to ~/.bashrc / a stray ~/.zshrc — harmless here
    # since our zsh reads from $ZDOTDIR, not ~/.zshrc.
    curl "${CURL_OPTS[@]}" -fsSL https://bun.sh/install | env BUN_INSTALL="$HOME/.local" bash
    success "bun installed"
}

# --- Neovim: apt's version is too old (this config needs 0.10+) -----------
install_neovim() {
    already_installed nvim && {
        log "nvim already installed, skipping"
        return
    }
    log "Installing neovim from upstream release..."
    local tmp
    tmp=$(mktemp -d)
    # `trap ... RETURN` is registered globally, not scoped to this function —
    # left alone, it fires again on the *next* function return anywhere in the
    # script (with $tmp now out of scope, which is a nounset error). Reset it
    # as part of firing so cleanup only ever applies to this invocation.
    trap 'rm -rf "$tmp"; trap - RETURN' RETURN
    curl "${CURL_OPTS[@]}" -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" -o "$tmp/nvim.tar.gz"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    local extracted
    extracted=$(find "$tmp" -maxdepth 1 -type d -name "nvim-linux*" | head -n1)
    if [[ -z "$extracted" ]]; then
        error "neovim archive didn't contain the expected nvim-linux* directory"
        return 1
    fi
    cp -r "$extracted"/* "$HOME/.local/"
    success "nvim -> $BIN_DIR/nvim"
}

# --- tmux plugin manager: tmux.conf already declares tmux-resurrect/
# tmux-continuum, but they do nothing until TPM itself is present. -----
install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        log "tpm already installed, skipping"
        return
    fi
    timeout 60 git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    success "tpm -> $tpm_dir (run 'prefix + I' inside tmux once to install plugins)"
}

# --- gh / terraform: official apt repositories (need sudo) ----------------

install_gh() {
    already_installed gh && {
        log "gh already installed, skipping"
        return
    }
    log "Installing gh via the official apt repo..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl "${CURL_OPTS[@]}" -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
        sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
        sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -qq && sudo apt-get install -y -qq gh
    success "gh installed"
}

install_terraform() {
    already_installed terraform && {
        log "terraform already installed, skipping"
        return
    }
    log "Installing terraform via the official HashiCorp apt repo..."
    local codename
    codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
    curl "${CURL_OPTS[@]}" -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $codename main" |
        sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    sudo apt-get update -qq && sudo apt-get install -y -qq terraform
    success "terraform installed"
}

main() {
    check_arch

    local failed=()
    run() {
        local name="$1"
        shift
        if ! "$@"; then
            error "$name failed to install — see message above"
            failed+=("$name")
        fi
    }

    run apt-renames link_apt_renamed_tools

    run chezmoi install_chezmoi
    run just install_just
    run starship install_starship
    run zoxide install_zoxide
    run sheldon install_sheldon
    run uv install_uv
    run bun install_bun
    run neovim install_neovim
    run tpm install_tpm

    run zellij install_from_github zellij zellij-org/zellij 'zellij-x86_64-unknown-linux-musl\.tar\.gz$'
    run lazygit install_from_github lazygit jesseduffield/lazygit 'lazygit_.*linux_x86_64\.tar\.gz$'
    run delta install_from_github delta dandavison/delta 'delta-.*-x86_64-unknown-linux-gnu\.tar\.gz$'
    run shfmt install_from_github shfmt mvdan/sh 'shfmt_.*_linux_amd64$'
    run age install_from_github age FiloSottile/age 'age-v.*-linux-amd64\.tar\.gz$'
    run gitleaks install_from_github gitleaks gitleaks/gitleaks 'gitleaks_.*_linux_x64\.tar\.gz$'
    run eza install_from_github eza eza-community/eza 'eza_x86_64-unknown-linux-gnu\.tar\.gz$'
    run fastfetch install_from_github fastfetch fastfetch-cli/fastfetch 'fastfetch-linux-amd64\.tar\.gz$'
    run atuin install_from_github atuin atuinsh/atuin 'atuin-x86_64-unknown-linux-gnu\.tar\.gz$'
    # apt's fzf is too old for the `fzf --zsh` integration tools.zsh uses (needs
    # 0.48+; Debian 12 ships 0.38, Ubuntu 24.04 ships 0.44) — same reason
    # neovim comes from upstream instead of apt.
    run fzf install_from_github fzf junegunn/fzf 'fzf-.*-linux_amd64\.tar\.gz$'

    # Generic ops/dev toolbelt: structured-data processing, resource
    # monitoring, HTTP debugging, dev-loop automation.
    run yq install_from_github yq mikefarah/yq 'yq_linux_amd64$'
    run bottom install_from_github btm ClementTsang/bottom 'bottom_x86_64-unknown-linux-gnu\.tar\.gz$'
    run xh install_from_github xh ducaale/xh 'xh-v.*-x86_64-unknown-linux-musl\.tar\.gz$'
    run watchexec install_from_github watchexec watchexec/watchexec 'watchexec-.*-x86_64-unknown-linux-gnu\.tar\.xz$'

    run gh install_gh
    run terraform install_terraform

    echo ""
    if [[ ${#failed[@]} -eq 0 ]]; then
        success "install-tools.sh done. Run 'just doctor' to verify everything is on PATH."
    else
        error "install-tools.sh finished with failures: ${failed[*]}"
        warn "Check the messages above, fix the affected install_* function, and re-run (it's idempotent)."
        exit 1
    fi
}

main "$@"
