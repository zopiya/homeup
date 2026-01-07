# shellcheck shell=bash
# ==============================================================================
# Zsh Functions
# ==============================================================================
# Purpose: Productivity functions for Python/Rust/Shell workflow
# ==============================================================================

# Cleanup potential aliases that conflict with function definitions
# This prevents "defining function based on alias" errors
unalias mkcd cl proj fcd bak unbak extract archive fkill port killport serve genpass 2>/dev/null

# ------------------------------------------------------------------------------
# Directory & Navigation
# ------------------------------------------------------------------------------

# Create directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# cd into directory and list contents
cl() {
    cd "$1" || return
    ls -la
}

# Jump to project directories (customize PROJECTS_ROOT as needed)
proj() {
    local PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Projects}"
    if [[ -n "$1" ]]; then
        cd "$PROJECTS_ROOT/$1" 2>/dev/null || echo "❌ Project '$1' not found"
    else
        cd "$PROJECTS_ROOT" || return
        ls -1
    fi
}

# Fuzzy find and cd into directory
fcd() {
    local dir
    # SC2086: Double quote to prevent globbing and word splitting
    dir=$(find "${1:-.}" -type d 2>/dev/null | fzf +m) && cd "$dir" || return
}

# ------------------------------------------------------------------------------
# File Operations
# ------------------------------------------------------------------------------

# Quick Backup (file -> file.bak.TIMESTAMP)
bak() {
    # SC2155: Declare and assign separately
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$1" "$1.bak.$timestamp" && echo "✅ Backed up $1 to $1.bak.$timestamp"
}

# Quick Restore (most recent .bak file)
unbak() {
    # Optimized: Use zsh glob qualifiers (.om[1]) instead of ls/head
    # . = regular files, om = order by modification time (newest first), [1] = take first, N = nullglob
    local latest

    # SC2039/SC3054: Disable warnings for Zsh-specific glob qualifiers
    # shellcheck disable=SC2039,SC3054
    latest=("${1}.bak."*(.om[1]N))

    # SC2128/SC2199/SC2145: Use [*] to expand array as a single string (safe here as we strictly target 1 file)
    if [[ -f "${latest[*]}" ]]; then
        mv "${latest[*]}" "$1" && echo "✅ Restored $1 from ${latest[*]}"
    else
        echo "❌ No backup found for $1"
    fi
}

# Extract any archive (enhanced with modern formats)
extract() {
    if [[ ! -f "$1" ]]; then
        echo "❌ '$1' is not a valid file"
        return 1
    fi

    case "$1" in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.tar.xz)    tar xJf "$1"     ;;
        *.tar.zst)   tar --zstd -xf "$1" ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       unrar x "$1"     ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *.xz)        unxz "$1"        ;;
        *.zst)       unzstd "$1"      ;;
        *.lz4)       lz4 -d "$1"      ;;
        *)           echo "❌ Cannot extract '$1': unknown format" ;;
    esac
}

# Create archive (smart format detection)
archive() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: archive <archive_name> <files...>"
        echo "Formats: .tar.gz, .tar.xz, .tar.zst, .zip, .7z"
        return 1
    fi

    local archive="$1"
    shift

    case "$archive" in
        *.tar.gz)    tar czf "$archive" "$@" ;;
        *.tar.xz)    tar cJf "$archive" "$@" ;;
        *.tar.zst)   tar --zstd -cf "$archive" "$@" ;;
        *.zip)       zip -r "$archive" "$@" ;;
        *.7z)        7z a "$archive" "$@" ;;
        *)           echo "❌ Unknown format: $archive" && return 1 ;;
    esac

    echo "✅ Created $archive"
}

# ------------------------------------------------------------------------------
# Process Management
# ------------------------------------------------------------------------------

# Fuzzy Kill Process (improved)
fkill() {
    local pid
    if [[ "$UID" != "0" ]]; then
        pid=$(ps -f -u "$UID" | sed 1d | fzf -m --preview 'echo {}' | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m --preview 'echo {}' | awk '{print $2}')
    fi

    if [[ -n "$pid" ]]; then
        echo "$pid" | xargs kill -"${1:-9}"
        echo "✅ Killed process(es): $pid"
    fi
}

# Find process by port
port() {
    if [[ -z "$1" ]]; then
        echo "Usage: port <port_number>"
        return 1
    fi
    lsof -i :"$1"
}

# Kill process on port
killport() {
    if [[ -z "$1" ]]; then
        echo "Usage: killport <port_number>"
        return 1
    fi

    local pid
    pid=$(lsof -ti :"$1")

    if [[ -n "$pid" ]]; then
        kill -9 "$pid" && echo "✅ Killed process on port $1 (PID: $pid)"
    else
        echo "❌ No process found on port $1"
    fi
}

# ------------------------------------------------------------------------------
# VS Code Profile Aliases (The "Co" Flow)
# ------------------------------------------------------------------------------

# Zen: Focused development (Default)
alias co='code --profile Zen'

# Lite: Quick edits, new window (Note-taking / Scratchpad)
alias col='code --profile Lite -n'

# View: Read-only / Code review (Minimal UI)
alias cov='code --profile View'

# Hub: Project management / Heavy lifting (Full UI)
alias coh='code --profile Hub'

# ------------------------------------------------------------------------------
# Tmux Session Management
# ------------------------------------------------------------------------------

# Quick attach or create session
tm() {
    if [[ -z "$1" ]]; then
        # No argument: show session list and attach to selected
        if command -v fzf &> /dev/null; then
            local session
            session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --prompt="Select session: ")
            [[ -n "$session" ]] && tmux attach-session -t "$session"
        else
            tmux list-sessions 2>/dev/null || echo "❌ No active sessions"
        fi
    else
        # Attach to existing or create new
        tmux attach-session -t "$1" 2>/dev/null || tmux new-session -s "$1"
    fi
}

# Kill tmux session
tmk() {
    if [[ -z "$1" ]]; then
        echo "Usage: tmk <session_name>"
        echo "Current sessions:"
        tmux list-sessions 2>/dev/null || echo "  (none)"
        return 1
    fi

    tmux kill-session -t "$1" 2>/dev/null && echo "✅ Killed session: $1" || echo "❌ Session not found: $1"
}

# Create project session (automatic directory-based session)
tmp() {
    local session_name
    local target_dir="${1:-.}"

    # Use directory name as session name
    session_name=$(basename "$(cd "$target_dir" && pwd)" | tr '.' '_')

    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux attach-session -t "$session_name"
    else
        tmux new-session -s "$session_name" -c "$target_dir"
    fi
}

# List all tmux sessions with details
tml() {
    if ! tmux list-sessions 2>/dev/null; then
        echo "❌ No active tmux sessions"
        return 1
    fi
}

# Tmux window switcher (fuzzy find)
tmw() {
    if [[ ! -n "$TMUX" ]]; then
        echo "❌ Not in a tmux session"
        return 1
    fi

    if command -v fzf &> /dev/null; then
        local window
        window=$(tmux list-windows -F "#{window_index}: #{window_name}" | fzf --prompt="Switch to window: ")
        [[ -n "$window" ]] && tmux select-window -t "${window%%:*}"
    else
        tmux list-windows
    fi
}

# Kill all tmux sessions (nuclear option)
tmka() {
    if tmux list-sessions 2>/dev/null; then
        read -q "REPLY?⚠️  Kill ALL tmux sessions? (y/n) "
        echo
        if [[ "$REPLY" == "y" ]]; then
            tmux kill-server && echo "✅ All sessions killed"
        else
            echo "❌ Aborted"
        fi
    else
        echo "❌ No active sessions"
    fi
}

# ------------------------------------------------------------------------------
# Misc Utilities
# ------------------------------------------------------------------------------

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    python -m http.server "$port"
}

# Generate random password
genpass() {
    local length="${1:-32}"
    LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "$length"
    echo
}
