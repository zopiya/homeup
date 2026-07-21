#!/usr/bin/env bash
# Restarts gpg-agent after chezmoi apply (re)writes GPG-related config, so it
# picks up changes without requiring a fresh login.
set -euo pipefail

if command -v gpgconf &>/dev/null; then
    gpgconf --kill gpg-agent 2>/dev/null || true
    gpgconf --launch gpg-agent 2>/dev/null || true
    echo "gpg-agent reloaded"
fi
