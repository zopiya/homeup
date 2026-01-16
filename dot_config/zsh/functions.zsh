# shellcheck shell=bash
# ==============================================================================
# Zsh Functions
# ==============================================================================
# Purpose: Productivity functions for Python/Rust/Shell workflow
# ==============================================================================

# Cleanup potential aliases that conflict with function definitions
# This prevents "defining function based on alias" errors
unalias mkcd cl proj fcd bak unbak extract archive fkill port killport serve genpass tm tmk tmp tml tmw tmka zjs zjk zjp yk 2>/dev/null

# ------------------------------------------------------------------------------
# YubiKey / FIDO2 SSH Key Management (macOS)
# ------------------------------------------------------------------------------

# Load resident SSH keys from YubiKey
# Usage: yk (run after inserting YubiKey)
yk() {
    # Use Homebrew ssh-add if available
    local ssh_add="${BREW_PREFIX:-/usr/local}/bin/ssh-add"
    [[ ! -x "$ssh_add" ]] && ssh_add="ssh-add"

    if "$ssh_add" -l &>/dev/null; then
        echo "SSH agent already has keys:"
        "$ssh_add" -l
    else
        echo "Loading YubiKey resident keys..."
        "$ssh_add" -K
    fi
}

# List SSH agent keys
yk-list() {
    local ssh_add="${BREW_PREFIX:-/usr/local}/bin/ssh-add"
    [[ ! -x "$ssh_add" ]] && ssh_add="ssh-add"
    "$ssh_add" -l
}

# Clear all keys from SSH agent
yk-clear() {
    local ssh_add="${BREW_PREFIX:-/usr/local}/bin/ssh-add"
    [[ ! -x "$ssh_add" ]] && ssh_add="ssh-add"
    "$ssh_add" -D && echo "All keys removed from agent"
}

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
# Usage: fcd [path] (default: .)
fcd() {
    local dir
    # Use fd if available for much better performance and .gitignore respect
    if command -v fd &> /dev/null; then
        dir=$(fd --type d --hidden --exclude .git "${1:-.}" | fzf +m)
    else
        dir=$(find "${1:-.}" -type d 2>/dev/null | fzf +m)
    fi
    [[ -n "$dir" ]] && cd "$dir" || return
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

# Quick Restore (mv latest .bak -> file)
# Usage: unbak <filename>
unbak() {
    # Optimized: Use zsh glob qualifiers (.om[1]) instead of ls/head
    # . = regular files, om = order by modification time (newest first), [1] = take first, N = nullglob
    local latest
    # FIX: Use simple assignment + array expansion to avoid parse errors in some zsh versions
    # When combined with complicated globs inside ()
    local -a files
    files=("${1}.bak."*(.om[1]N))
    latest="${files[1]}"

    if [[ -f "$latest" ]]; then
        mv "$latest" "$1" && echo "✅ Restored $1 from $latest"
    else
        echo "❌ No backup found for $1"
    fi
}

# Extract any archive (enhanced with modern formats)
# Usage: extract <file> (e.g. tar.gz, zip, 7z, rar, xz...)
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
# Usage: archive <out.ext> <files...>
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
        *.tar)       tar cf "$archive" "$@" ;;  # Added basic tar support
        *)           echo "❌ Unknown format: $archive" && return 1 ;;
    esac

    echo "✅ Created $archive"
}

# ------------------------------------------------------------------------------
# Process Management
# ------------------------------------------------------------------------------

# Interactive process killer
# Usage: fkill [signal] (default: 9)
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

# Tmux smart attach/create/select
# Usage: tm [name] (No args = fuzzy selection)
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

# Create/Attach directory-based tmux session
# Usage: tmp [dir] (default: current dir)
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
        # shellcheck disable=SC2162 # read -q is specific to zsh
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

# ------------------------------------------------------------------------------
# Terminal Multiplexer
# ------------------------------------------------------------------------------

# Zellij smart attach/create/select
# Usage: zjs [name] (No args = fuzzy selection)
zjs() {
    if [[ -n "$1" ]]; then
        # If argument provided: attach to it or create with that name
        zellij attach "$1" 2>/dev/null || zellij --session "$1"
    else
        # No argument provided: interactive selection
        local sessions
        # Strip ANSI codes from output just in case
        sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')

        if [[ -z "$sessions" ]]; then
            # No active sessions, start a new one
            zellij
            return
        fi

        if command -v fzf &> /dev/null; then
            local session
            # Extract session name (first column) and select via fzf
            session=$(echo "$sessions" | fzf --prompt="Select Zellij session: " --height=40% --layout=reverse --border | awk '{print $1}')

            if [[ -n "$session" ]]; then
                zellij attach "$session"
            else
                # If selection cancelled, do nothing (comment out next line to auto-create)
                # echo "No session selected."
                :
            fi
        else
            # Fallback if fzf is missing
            echo "Available sessions:"
            echo "$sessions"
            echo ""
            read -r "sname?Enter session name (or press Enter for new): "
            if [[ -n "$sname" ]]; then
                zellij attach "$sname"
            else
                zellij
            fi
        fi
    fi
}

# Delete Zellij session(s)
# Usage: zjk [name] (No args = multi-select via fzf)
zjk() {
    if [[ -n "$1" ]]; then
        zellij delete-session "$1"
    else
        if command -v fzf &> /dev/null; then
            local sessions
            # Allow multiple selection with Tab
            sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' | fzf --multi --prompt="Delete Zellij session(s): " | awk '{print $1}')

            if [[ -n "$sessions" ]]; then
                echo "$sessions" | xargs -I{} zellij delete-session "{}"
                echo "✅ Deleted session(s)"
            fi
        else
            # Fallback
            local sname
            zellij list-sessions 2>/dev/null
            read -r "sname?Enter session name to kill: "
            [[ -n "$sname" ]] && zellij delete-session "$sname"
        fi
    fi
}

# Kill ALL Zellij sessions
zjka() {
    local sessions
    sessions=$(zellij list-sessions 2>/dev/null)

    if [[ -z "$sessions" ]]; then
        echo "❌ No active Zellij sessions"
        return
    fi

    # shellcheck disable=SC2162 # read -q is specific to zsh
    read -q "REPLY?⚠️  Kill ALL Zellij sessions? (y/n) "
    echo
    if [[ "$REPLY" == "y" ]]; then
        echo "$sessions" | awk '{print $1}' | xargs -I{} zellij delete-session "{}" 2>/dev/null
        echo "✅ All sessions killed"
    else
        echo "❌ Aborted"
    fi
}

# Create/Attach project-specific Zellij session
# Usage: zjp [project_name] [layout]
# Examples:
#   zjp              # Current dir, base layout
#   zjp my-app       # Named session, base layout
#   zjp . ops        # Current dir, ops layout
zjp() {
    local project_name="${1:-$(basename "$PWD")}"
    local layout="${2:-base}"  # Default: Base layout (Minimal)

    # Handle "." as explicitly using current dir name
    if [[ "$project_name" == "." ]]; then
        project_name="$(basename "$PWD")"
    fi

    # Sanitize project name (replace invalid chars with underscores)
    project_name="${project_name//[^a-zA-Z0-9_-]/_}"

    # Determine theme based on layout for visual distinction
    local theme=""
    case "$layout" in
        dev)  theme="catppuccin-mocha" ;; # Dev: Soft pastel (Purple/Blue)
        ops)  theme="compact"          ;; # Ops: High contrast / Compact
        *)    theme="github-dark"      ;; # Base: Standard dark theme
    esac

    # Check if session exists (ignoring case/colors)
    # Using perl to strip ANSI color codes for reliable matching
    if zellij list-sessions 2>/dev/null | perl -pe 's/\e\[?.*?[\@-~]//g' | awk '{print $1}' | grep -qx "$project_name"; then
        echo "🔄 Attaching to existing session: $project_name"
        zellij attach "$project_name"
    else
        echo "✨ Creating new session: $project_name (Layout: $layout, Theme: $theme)"
        # Note: --theme logic relies on Zellij supporting config override via flags or environment.
        # Since 'zellij [options]' syntax varies, we define it here if supported.
        # If specific version doesn't support --theme flag at root, this might need 'options --theme'.
        # Assuming modern Zellij:
        zellij --session "$project_name" --layout "$layout" options --theme "$theme"
    fi
}
