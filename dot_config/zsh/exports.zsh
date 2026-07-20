# ==============================================================================
# Zsh Exports
# ==============================================================================

# --- Locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- Pager ---
# Use bat to render man pages with syntax highlighting
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"
export LESS='-R --use-color -Dd+r -Du+b'

# --- Colors ---
export BAT_THEME="GitHub"

# --- FZF ---
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --bind=ctrl-d:half-page-down,ctrl-u:half-page-up'

# --- History ---
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

