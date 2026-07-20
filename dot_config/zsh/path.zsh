# ==============================================================================
# PATH & Tool Environment
# ==============================================================================
# Purpose: Prioritize user-local tool installs over system-provided binaries.
#
# apt-installed packages already live on $PATH via /usr/bin. Tools installed
# by packages/install-tools.sh (chezmoi, just, starship, ...) and anything
# built via cargo land in ~/.local/bin / ~/.cargo/bin instead — prepend both
# so they take priority over any older apt-packaged version of the same tool.
# ==============================================================================

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
