# General
alias ls="eza --group-directories-first"
alias ll="eza --group-directories-first -l"
alias la="eza --group-directories-first -la"
alias tree="eza --tree"
alias cat="bat"
alias grep="rg"
alias f="fd"
alias cd="z"
alias zi="z -i"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -="cd -"

# Utils
alias path='echo $PATH | tr ":" "\n"'

# Safety
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

# Network & System
alias ports="lsof -i -P -n | grep LISTEN"
alias myip="curl -s https://api.ipify.org; echo"

# Systemd / journalctl
alias jf="journalctl -f"
alias jctl="journalctl -xe"
alias jstat="systemctl status"
alias jre="sudo systemctl restart"
alias jenable="sudo systemctl enable --now"

# Git
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

# Neovim
alias v="nvim"
alias vim="nvim"

# Terminal multiplexers
alias tma="tmux attach"
alias tmn="tmux new-session"
alias zj="zellij"
alias zja="zellij attach"
alias zjl="zellij list-sessions"
alias zjz="zellij --layout zen"
alias zjd="zellij --layout dev"

# Chezmoi
alias cm="chezmoi"
alias cma="chezmoi apply"
alias cmu="chezmoi update"
alias cme="chezmoi edit"

# AI backends（快速切换，日常用 ai 函数即可）
alias oc="opencode"
alias cld="claude"   # cc 与系统 C 编译器 /usr/bin/cc 冲突，改用 cld

# Misc
alias reload="exec zsh -l"
