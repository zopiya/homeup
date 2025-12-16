# Create directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# cd into directory and list contents
cl() {
    cd "$1" && ls
}

# Quick Backup (file -> file.bak)
bak() {
    cp "$1" "$1.bak" && echo "✅ Backed up $1 to $1.bak"
}

# Quick Restore (file.bak -> file)
unbak() {
    mv "$1.bak" "$1" && echo "✅ Restored $1 from $1.bak"
}

# Cheat Sheet (e.g., cht tar)
cht() {
    curl "cht.sh/$1"
}

# Git Commit & Push
gcp() {
    git add . && git commit -m "$1" && git push
}

# Fuzzy Find & Edit
fe() {
  local files=($(fzf --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# Fuzzy Kill Process
fkill() {
  local pid
  if [ "$UID" != "0" ]; then
    pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
  else
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  fi

  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

# Extract any archive
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
