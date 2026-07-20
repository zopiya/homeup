# ==============================================================================
# Zsh Options
# ==============================================================================

# --- History ---
setopt HIST_IGNORE_DUPS       # Don't record consecutive duplicate commands
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates from history
setopt HIST_IGNORE_SPACE      # Don't record commands starting with a space
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks
setopt HIST_SAVE_NO_DUPS      # Don't save duplicates to history file
setopt HIST_VERIFY            # Show command before executing from history
setopt SHARE_HISTORY          # Share history across all sessions
setopt EXTENDED_HISTORY       # Record timestamp and duration

# --- Directory Navigation ---
setopt AUTO_PUSHD             # Push previous dir onto stack on cd
setopt PUSHD_IGNORE_DUPS      # Don't push duplicate directories
setopt PUSHD_SILENT           # Don't print stack after pushd/popd

# --- Completion ---
setopt AUTO_MENU              # Show completion menu on successive tab press
setopt COMPLETE_IN_WORD       # Complete from both ends of a word
setopt ALWAYS_TO_END          # Move cursor to end after completion

# --- Globbing ---
setopt EXTENDED_GLOB          # Enable extended glob patterns (#, ~, ^)

# --- Misc ---
setopt NO_BEEP                # Disable audible bell
setopt INTERACTIVE_COMMENTS   # Allow # comments in interactive shell
setopt COMBINING_CHARS        # Better handling of Unicode combining chars
