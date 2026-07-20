# ==============================================================================
# Development Tools Initialization
# ==============================================================================
# Purpose: Initialize shell integrations for development tools.
#
# Each tool is initialized only if installed. Order matters:
#   1. Sheldon (plugins) must be before compinit
#   2. compinit must be after all fpath modifications
#   3. FZF after compinit
#   4. direnv before prompt (env vars must be set before starship renders)
# ==============================================================================

# ------------------------------------------------------------------------------
# Plugin Manager
# ------------------------------------------------------------------------------

# Sheldon (zsh plugin manager) - loads zsh-completions which modifies fpath
if command -v sheldon &>/dev/null; then
    eval "$(sheldon source)"
fi

# ------------------------------------------------------------------------------
# Completion System
# ------------------------------------------------------------------------------
# Cache compinit dump for 24 hours to speed up startup

autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------
# Per-directory environment variable management (direnv)

if command -v direnv &>/dev/null; then
    eval "$(direnv hook zsh)"
fi

# ------------------------------------------------------------------------------
# Prompt
# ------------------------------------------------------------------------------

# Starship (cross-shell prompt)
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# ------------------------------------------------------------------------------
# Navigation
# ------------------------------------------------------------------------------

# Zoxide (smart cd replacement)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi


# ------------------------------------------------------------------------------
# Search & Filtering
# ------------------------------------------------------------------------------

# FZF (fuzzy finder) - use native shell integration (fzf 0.48+)
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------

# Atuin (shell history sync & search)
if command -v atuin &>/dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# ------------------------------------------------------------------------------
# Language Runtimes
# ------------------------------------------------------------------------------
# Shell completions for language runtimes (beyond what compinit auto-discovers)

# Bun (JavaScript runtime)
if command -v bun &>/dev/null; then
    [ -s "$(bun completions 2>/dev/null)" ] && source <(bun completions)
fi

# Python toolchain
if command -v uv &>/dev/null; then
    eval "$(uv generate-shell-completion zsh 2>/dev/null)"
fi

if command -v uvx &>/dev/null; then
    eval "$(uvx generate-shell-completion zsh 2>/dev/null)"
fi

# ------------------------------------------------------------------------------
# Plugin Keybindings
# ------------------------------------------------------------------------------
# Deferred keybindings (plugins are loaded async via zsh-defer)

# History substring search: arrow keys navigate matching history
zsh-defer bindkey "^[[A" history-substring-search-up
zsh-defer bindkey "^[[B" history-substring-search-down
zsh-defer bindkey "^P" history-substring-search-up
zsh-defer bindkey "^N" history-substring-search-down

