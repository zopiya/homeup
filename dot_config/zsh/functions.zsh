
# ==============================================================================
# Zsh Functions
# ==============================================================================
# Purpose: Productivity functions for Python/Rust/Shell workflow
# ==============================================================================

# ------------------------------------------------------------------------------
# Directory & Navigation
# ------------------------------------------------------------------------------

mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

cl() {
    cd "$1" || return
    ls -la
}

proj() {
    local PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Projects}"
    if [[ -n "$1" ]]; then
        cd "$PROJECTS_ROOT/$1" 2>/dev/null || echo "❌ Project '$1' not found"
    else
        cd "$PROJECTS_ROOT" || return
        ls -1
    fi
}

fcd() {
    local dir
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

bak() {
    [[ -z "$1" ]] && { echo "Usage: bak <file>"; return 1; }
    [[ ! -f "$1" ]] && { echo "❌ File not found: $1"; return 1; }
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$1" "$1.bak.$timestamp" && echo "✅ Backed up $1 to $1.bak.$timestamp"
}

unbak() {
    local backup="${1}.bak"
    local target="$1"

    if [[ ! -e "$backup" ]]; then
        echo "No backup found for $target"
        return 1
    fi

    local newest
    newest=$(ls -t "${backup}".* 2>/dev/null | head -1)

    if [[ -z "$newest" ]]; then
        echo "No backup found for $target"
        return 1
    fi

    if [[ ! -f "$newest" ]]; then
        echo "Backup is not a regular file: $newest"
        return 1
    fi

    cp -p "$newest" "$target"
    echo "Restored: $newest -> $target"
}

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
        *.tar)       tar cf "$archive" "$@" ;;
        *)           echo "❌ Unknown format: $archive" && return 1 ;;
    esac

    echo "✅ Created $archive"
}

# ------------------------------------------------------------------------------
# Process Management
# ------------------------------------------------------------------------------

fkill() {
    local pid
    local target_uid="${1:-$UID}"
    pid=$(ps -f -u "$target_uid" 2>/dev/null | sed 1d | fzf -m --preview 'echo {}' | awk '{print $2}')
    if [[ -z "$pid" ]]; then
        echo "No process selected"
        return 1
    fi
    echo "Killing: $pid"
    kill $pid
}

port() {
    if [[ -z "$1" ]]; then
        echo "Usage: port <port_number>"
        return 1
    fi
    lsof -i :"$1"
}

killport() {
    if [[ -z "$1" ]]; then
        echo "Usage: killport <port_number>"
        return 1
    fi

    local pid
    pid=$(lsof -ti :"$1")

    if [[ -n "$pid" ]]; then
        echo "$pid" | xargs kill -9 && echo "✅ Killed process on port $1 (PID: $pid)"
    else
        echo "❌ No process found on port $1"
    fi
}

# ------------------------------------------------------------------------------
# Tmux Session Management
# ------------------------------------------------------------------------------

tm() {
    if [[ -z "$1" ]]; then
        if command -v fzf &> /dev/null; then
            local session
            session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --prompt="Select session: ")
            [[ -n "$session" ]] && tmux attach-session -t "$session"
        else
            tmux list-sessions 2>/dev/null || echo "❌ No active sessions"
        fi
    else
        tmux attach-session -t "$1" 2>/dev/null || tmux new-session -s "$1"
    fi
}

tmk() {
    if [[ -z "$1" ]]; then
        echo "Usage: tmk <session_name>"
        echo "Current sessions:"
        tmux list-sessions 2>/dev/null || echo "  (none)"
        return 1
    fi

    tmux kill-session -t "$1" 2>/dev/null && echo "✅ Killed session: $1" || echo "❌ Session not found: $1"
}

tmp() {
    local session_name
    local target_dir="${1:-.}"

    [[ ! -d "$target_dir" ]] && { echo "❌ Directory not found: $target_dir"; return 1; }
    session_name=$(basename "$(cd "$target_dir" && pwd)" | tr '.' '_')

    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux attach-session -t "$session_name"
    else
        tmux new-session -s "$session_name" -c "$target_dir"
    fi
}

tml() {
    if ! tmux list-sessions 2>/dev/null; then
        echo "❌ No active tmux sessions"
        return 1
    fi
}

tmw() {
    if [[ -z "$TMUX" ]]; then
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

serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

genpass() {
    local length="${1:-32}"
    LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "$length"
    echo
}

# ------------------------------------------------------------------------------
# Terminal Multiplexer
# ------------------------------------------------------------------------------

zjs() {
    if [[ -n "$1" ]]; then
        zellij attach "$1" 2>/dev/null || zellij --session "$1"
    else
        local sessions
        sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')

        if [[ -z "$sessions" ]]; then
            zellij
            return
        fi

        if command -v fzf &> /dev/null; then
            local session
            session=$(echo "$sessions" | fzf --prompt="Select Zellij session: " --height=40% --layout=reverse --border | awk '{print $1}')
            [[ -n "$session" ]] && zellij attach "$session"
        else
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

zjk() {
    if [[ -n "$1" ]]; then
        zellij delete-session "$1"
    else
        if command -v fzf &> /dev/null; then
            local sessions
            sessions=$(zellij list-sessions 2>/dev/null | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' | fzf --multi --prompt="Delete Zellij session(s): " | awk '{print $1}')

            if [[ -n "$sessions" ]]; then
                echo "$sessions" | xargs -I{} zellij delete-session "{}"
                echo "✅ Deleted session(s)"
            fi
        else
            local sname
            zellij list-sessions 2>/dev/null
            read -r "sname?Enter session name to kill: "
            [[ -n "$sname" ]] && zellij delete-session "$sname"
        fi
    fi
}

zjka() {
    local sessions
    sessions=$(zellij list-sessions 2>/dev/null)

    if [[ -z "$sessions" ]]; then
        echo "❌ No active Zellij sessions"
        return
    fi

    read -q "REPLY?⚠️  Kill ALL Zellij sessions? (y/n) "
    echo
    if [[ "$REPLY" == "y" ]]; then
        echo "$sessions" | awk '{print $1}' | xargs -I{} zellij delete-session "{}" 2>/dev/null
        echo "✅ All sessions killed"
    else
        echo "❌ Aborted"
    fi
}

zjp() {
    local project_name="${1:-$(basename "$PWD")}"
    local layout="${2:-base}"

    if [[ "$project_name" == "." ]]; then
        project_name="$(basename "$PWD")"
    fi

    project_name="${project_name//[^a-zA-Z0-9_-]/_}"

    local theme=""
    case "$layout" in
        dev)  theme="catppuccin-mocha" ;;
        ops)  theme="compact" ;;
        *)    theme="github-dark" ;;
    esac

    if zellij list-sessions 2>/dev/null | perl -pe 's/\e\[?.*?[\@-~]//g' | awk '{print $1}' | grep -qx "$project_name"; then
        echo "🔄 Attaching to existing session: $project_name"
        zellij attach "$project_name"
    else
        echo "✨ Creating new session: $project_name (Layout: $layout, Theme: $theme)"
        zellij --session "$project_name" --layout "$layout" options --theme "$theme"
    fi
}
