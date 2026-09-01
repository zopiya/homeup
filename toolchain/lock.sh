#!/usr/bin/env bash
# shellcheck shell=bash
# Single source of truth for every version-sensitive, non-apt artifact.
# Update this file only through a reviewed lock update. URLs are immutable
# release URLs and every installer verifies the matching SHA-256 first.

# shellcheck disable=SC2034 # Public metadata consumed by lock validators.
readonly HOMEUP_LOCK_REVISION="2026-08-12.2"

lock_version() {
    case "$1" in
    just) printf '%s\n' '1.58.0' ;;
    chezmoi) printf '%s\n' '2.72.1' ;;
    sheldon) printf '%s\n' '0.8.5' ;;
    node) printf '%s\n' '24.20.0' ;;
    bun) printf '%s\n' '1.4.0' ;;
    python) printf '%s\n' '3.14.7' ;;
    rust) printf '%s\n' '1.98.0' ;;
    *) return 1 ;;
    esac
}

lock_url() {
    local component="$1" arch="$2"
    case "$component:$arch" in
    just:amd64) printf '%s\n' 'https://github.com/casey/just/releases/download/1.58.0/just-1.58.0-x86_64-unknown-linux-musl.tar.gz' ;;
    chezmoi:amd64) printf '%s\n' 'https://github.com/twpayne/chezmoi/releases/download/v2.72.1/chezmoi_2.72.1_linux_amd64.tar.gz' ;;
    sheldon:amd64) printf '%s\n' 'https://github.com/rossmacarthur/sheldon/releases/download/0.8.5/sheldon-0.8.5-x86_64-unknown-linux-musl.tar.gz' ;;
    node:amd64) printf '%s\n' 'https://nodejs.org/dist/v24.20.0/node-v24.20.0-linux-x64.tar.xz' ;;
    bun:amd64) printf '%s\n' 'https://github.com/oven-sh/bun/releases/download/bun-v1.4.0/bun-linux-x64.zip' ;;
    python:amd64) printf '%s\n' 'https://github.com/astral-sh/python-build-standalone/releases/download/20260825/cpython-3.14.7%2B20260825-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz' ;;
    rust:amd64) printf '%s\n' 'https://static.rust-lang.org/dist/2026-08-20/rust-1.98.0-x86_64-unknown-linux-gnu.tar.xz' ;;
    *) return 1 ;;
    esac
}

lock_sha256() {
    local component="$1" arch="$2"
    case "$component:$arch" in
    just:amd64) printf '%s\n' '4a5cc2f53e6f0f8c59092a6cc38291eb729d46a7dd95d3ae582008881b84931d' ;;
    chezmoi:amd64) printf '%s\n' '9f97d32caca166e5c92160ec3a9325519809c38963121cef38173142065c981f' ;;
    sheldon:amd64) printf '%s\n' '80aa0be617072c278d67fd6c5fbce4903d3801d78b6abf8f058f0648d2242c78' ;;
    node:amd64) printf '%s\n' '2f2c0da162318f0de47665410c7c8c2ed3d36c8f3105de4bbc61176c70a7cbf2' ;;
    bun:amd64) printf '%s\n' '2d03fb5fb83ac8b567aca0a281b2ce1a1a19d488f56c2968d88c3f25e92fe452' ;;
    python:amd64) printf '%s\n' 'a0f39e822fd3b96a2605f30f954acf9a2cdf91faa1385a13e24bc407a41e05ea' ;;
    rust:amd64) printf '%s\n' 'ed8ee2df70909c88cbaf87a6cfa3920dac00b537de12a6abe6906641e0f5952f' ;;
    *) return 1 ;;
    esac
}

lock_components() {
    printf '%s\n' just chezmoi sheldon node bun python rust
}

# Destination and command metadata keep the lock self-describing. The
# installer may choose a system or user-owned prefix, but it may not change
# these relative destinations or installed components.
lock_destination() {
    case "$1" in
    just | chezmoi | sheldon) printf '%s\n' 'bin' ;;
    node | bun | python | rust) printf '%s\n' 'opt' ;;
    *) return 1 ;;
    esac
}

lock_install_components() {
    case "$1" in
    just) printf '%s\n' 'just' ;;
    chezmoi) printf '%s\n' 'chezmoi' ;;
    sheldon) printf '%s\n' 'sheldon' ;;
    node) printf '%s\n' 'node npm npx corepack' ;;
    bun) printf '%s\n' 'bun' ;;
    python) printf '%s\n' 'python python3 pip pip3' ;;
    rust) printf '%s\n' 'cargo rustc rustdoc rustfmt clippy-driver' ;;
    *) return 1 ;;
    esac
}

lock_tpm_repository() { printf '%s\n' 'https://github.com/tmux-plugins/tpm.git'; }
lock_tpm_revision() { printf '%s\n' 'e261deb1b47614eed3400089ce7197dc68acc4eb'; }
lock_tpm_url() { printf '%s\n' 'https://github.com/tmux-plugins/tpm/archive/e261deb1b47614eed3400089ce7197dc68acc4eb.tar.gz'; }
lock_tpm_sha256() { printf '%s\n' '72d92c512270d4857e27519ac97b92a52cf149afe4d92f26860c710f60bbbe37'; }
