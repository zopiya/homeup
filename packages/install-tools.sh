#!/usr/bin/env bash
# Day 1 tool installer — for CLI tools that apt either doesn't package or
# ships too old a version of (see packages/apt-packages.txt for the rest that
# come straight from apt). Installs everything into ~/.local/bin, which
# dot_config/zsh/path.zsh already puts first on PATH. Safe to re-run: each
# installer is skipped once the tool is already found on PATH.
#
# Assumes linux-x86_64/amd64. On arm64 the release-asset patterns below will
# need adjusting (grep for "aarch64"/"arm64" instead).
#
# The GitHub-release patterns here were written from memory of each project's
# current release-asset naming; they can drift when a project changes its
# release tooling. If install_from_github fails to find a match, check the
# project's actual "latest" release page and fix the pattern below.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

log() { echo "==> $*"; }
already_installed() { command -v "$1" &>/dev/null; }

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
# $BIN_DIR. Handles both archives (tar.gz/tgz/zip) and bare binary assets.
install_from_github() {
    local bin="$1" repo="$2" pattern="$3"
    if already_installed "$bin"; then
        log "$bin already installed, skipping"
        return
    fi

    log "Installing $bin from $repo..."
    local url
    url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
        grep -o '"browser_download_url": *"[^"]*"' |
        cut -d'"' -f4 |
        grep -iE "$pattern" | head -n1)
    if [[ -z "$url" ]]; then
        echo "  could not find a release asset matching '$pattern' for $repo — skipping" >&2
        return 1
    fi

    local tmp
    tmp=$(mktemp -d)
    curl -fsSL "$url" -o "$tmp/asset"

    case "$url" in
    *.tar.gz | *.tgz) tar -xzf "$tmp/asset" -C "$tmp" ;;
    *.zip) (cd "$tmp" && unzip -q asset) ;;
    *) mv "$tmp/asset" "$tmp/$bin" ;;
    esac

    local found
    found=$(find "$tmp" -type f -iname "$bin" | head -n1)
    if [[ -z "$found" ]]; then
        echo "  could not locate '$bin' binary inside the downloaded asset" >&2
        rm -rf "$tmp"
        return 1
    fi
    install -m755 "$found" "$BIN_DIR/$bin"
    rm -rf "$tmp"
    log "$bin -> $BIN_DIR/$bin"
}

# --- Official installer scripts (already support a custom bin dir) --------

install_chezmoi() {
    already_installed chezmoi && {
        log "chezmoi already installed, skipping"
        return
    }
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
}

install_just() {
    already_installed just && {
        log "just already installed, skipping"
        return
    }
    curl --proto '=https' --tlsv1.2 -fsSL https://just.systems/install.sh | bash -s -- --to "$BIN_DIR"
}

install_starship() {
    already_installed starship && {
        log "starship already installed, skipping"
        return
    }
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$BIN_DIR"
}

install_zoxide() {
    already_installed zoxide && {
        log "zoxide already installed, skipping"
        return
    }
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$BIN_DIR"
}

install_sheldon() {
    already_installed sheldon && {
        log "sheldon already installed, skipping"
        return
    }
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --to "$BIN_DIR"
}

install_uv() {
    already_installed uv && {
        log "uv already installed, skipping"
        return
    }
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$BIN_DIR" sh
}

install_bun() {
    already_installed bun && {
        log "bun already installed, skipping"
        return
    }
    # BUN_INSTALL=~/.local makes the installer place the binary at ~/.local/bin/bun.
    # It may also append PATH lines to ~/.bashrc / a stray ~/.zshrc — harmless here
    # since our zsh reads from $ZDOTDIR, not ~/.zshrc.
    curl -fsSL https://bun.sh/install | env BUN_INSTALL="$HOME/.local" bash
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
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" -o "$tmp/nvim.tar.gz"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    local extracted
    extracted=$(find "$tmp" -maxdepth 1 -type d -name "nvim-linux*" | head -n1)
    cp -r "$extracted"/* "$HOME/.local/"
    rm -rf "$tmp"
    log "nvim -> $BIN_DIR/nvim"
}

# --- gh / terraform: official apt repositories (need sudo) ----------------

install_gh() {
    already_installed gh && {
        log "gh already installed, skipping"
        return
    }
    log "Installing gh via the official apt repo..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
        sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
        sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -qq && sudo apt-get install -y -qq gh
}

install_terraform() {
    already_installed terraform && {
        log "terraform already installed, skipping"
        return
    }
    log "Installing terraform via the official HashiCorp apt repo..."
    local codename
    codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $codename main" |
        sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    sudo apt-get update -qq && sudo apt-get install -y -qq terraform
}

install_ollama() {
    already_installed ollama && {
        log "ollama already installed, skipping"
        return
    }
    curl -fsSL https://ollama.com/install.sh | sh
}

install_fava() {
    already_installed fava && {
        log "fava already installed, skipping"
        return
    }
    sudo apt-get install -y -qq pipx
    pipx install fava
}

main() {
    local failed=()
    run() {
        local name="$1"
        shift
        "$@" || failed+=("$name")
    }

    link_apt_renamed_tools

    run chezmoi install_chezmoi
    run just install_just
    run starship install_starship
    run zoxide install_zoxide
    run sheldon install_sheldon
    run uv install_uv
    run bun install_bun
    run neovim install_neovim

    run zellij install_from_github zellij zellij-org/zellij 'zellij-x86_64-unknown-linux-musl\.tar\.gz$'
    run lazygit install_from_github lazygit jesseduffield/lazygit 'lazygit_.*linux_x86_64\.tar\.gz$'
    run delta install_from_github delta dandavison/delta 'delta-.*-x86_64-unknown-linux-gnu\.tar\.gz$'
    run shfmt install_from_github shfmt mvdan/sh 'shfmt_.*_linux_amd64$'
    run age install_from_github age FiloSottile/age 'age-v.*-linux-amd64\.tar\.gz$'
    run gitleaks install_from_github gitleaks gitleaks/gitleaks 'gitleaks_.*_linux_x64\.tar\.gz$'
    run eza install_from_github eza eza-community/eza 'eza_x86_64-unknown-linux-gnu\.tar\.gz$'
    run fastfetch install_from_github fastfetch fastfetch-cli/fastfetch 'fastfetch-linux-amd64\.tar\.gz$'
    run atuin install_from_github atuin atuinsh/atuin 'atuin-x86_64-unknown-linux-gnu\.tar\.gz$'

    run gh install_gh
    run terraform install_terraform
    run ollama install_ollama
    run fava install_fava

    echo ""
    if [[ ${#failed[@]} -eq 0 ]]; then
        echo "install-tools.sh done. Run 'just doctor' to verify everything is on PATH."
    else
        echo "install-tools.sh finished with failures: ${failed[*]}"
        echo "Check the messages above, fix the affected install_* function, and re-run (it's idempotent)."
        exit 1
    fi
}

main "$@"
