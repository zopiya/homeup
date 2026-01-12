# ==============================================================================
# Zsh Aliases
# ==============================================================================

# --- General ---
alias ls="eza --group-directories-first"
alias ll="eza --group-directories-first -l"
alias la="eza --group-directories-first -la"
alias tree="eza --tree"
alias cat="bat"
alias grep="rg"
alias f="fd"
alias cd="z"
alias zi="z -i"

# --- Navigation ---
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -="cd -"

# --- Utils ---
alias path='echo $PATH | tr ":" "\n"'

# --- Safety ---
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

# --- Network & System ---
alias ports="lsof -i -P -n | grep LISTEN"
alias myip="curl http://ipecho.net/plain; echo"
alias serve="python3 -m http.server"

# --- Git ---
alias g="git"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -m"
alias gs="git status"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias gundo="git reset --soft HEAD~1"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias lg="lazygit"

# --- Neovim ---
alias v="nvim"
alias vim="nvim"

# --- Terminal Multiplexers ---
alias tm="tmux"
alias tma="tmux attach"
alias tmn="tmux new-session"
alias zj="zellij"                    # Default layout
alias zja="zellij attach"
alias zjl="zellij list-sessions"
# Core layouts
alias zjz="zellij --layout zen"     # Focus: Minimalist concentration
alias zjh="zellij --layout hub"     # Hub: Complete workspace
alias zjd="zellij --layout dev"     # Dev: AI-first development
# Legacy compatibility
alias cm="chezmoi"
alias cma="chezmoi apply"
alias cmu="chezmoi update"
alias cme="chezmoi edit"

# --- Misc ---
alias reload="source ~/.zshrc && echo 'Shell config reloaded.'"
