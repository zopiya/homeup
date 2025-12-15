#!/bin/bash

# Homeup Bootstrap Script
# Purpose: Initialize the environment from scratch (bare metal)
# 1. Detects OS and Architecture
# 2. Installs Homebrew
# 3. Installs Chezmoi
# 4. Initializes Homeup

set -e # Exit on error

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Output Styling & Helper Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Icons
readonly ICON_START="🚀"
readonly ICON_PKG="📦"
readonly ICON_CONF="🔧"
readonly ICON_SUCCESS="✅"
readonly ICON_FAIL="❌"
readonly ICON_WARN="⚠️ "
readonly ICON_INFO="💡"
readonly ICON_CHECK="🔍"
readonly ICON_WAIT="⏳"

info() {
    echo -e "${BLUE}${ICON_INFO}  $1${NC}"
}

success() {
    echo -e "${GREEN}${ICON_SUCCESS}  $1${NC}"
}

error() {
    echo -e "${RED}${ICON_FAIL}  $1${NC}"
}

warning() {
    echo -e "${YELLOW}${ICON_WARN}  $1${NC}"
}

step() {
    local current=$1
    local total=$2
    local message=$3
    echo ""
    echo -e "${CYAN}[$current/$total] $message${NC}"
}

header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}${ICON_START}  $1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Spinner for long running tasks
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    echo -n "  ${ICON_WAIT} $message "
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "   \b\b\b"
    echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main Execution
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "Homeup Bootstrap Starting..."

# 1. Detect OS and Architecture
step 1 4 "Detecting system..."
OS="$(uname -s)"
ARCH="$(uname -m)"

echo -e "  ✓ OS: $OS"
echo -e "  ✓ Arch: $ARCH"

# 2. Install Dependencies (Linux only)
if [ "$OS" = "Linux" ]; then
    step 2 4 "Installing Linux dependencies..."
    
    SUDO=""
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    elif [ "$EUID" -ne 0 ]; then
        error "This script requires root privileges or sudo to install dependencies."
        exit 1
    fi

    if command -v apt-get &> /dev/null; then
        $SUDO apt-get update > /dev/null 2>&1 &
        spinner $! "Updating apt repositories..."
        
        $SUDO apt-get install -y git curl build-essential procps file > /dev/null 2>&1 &
        spinner $! "Installing packages..."
    elif command -v dnf &> /dev/null; then
        $SUDO dnf install -y git curl @development-tools procps-ng file > /dev/null 2>&1 &
        spinner $! "Installing packages..."
    else
        error "Unsupported Linux distribution. Please install git, curl, and build-essential manually."
        exit 1
    fi
    success "Dependencies installed"
fi

# 3. Install Homebrew
step 2 4 "Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    info "Homebrew not found. Installing..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null 2>&1 &
    spinner $! "Downloading and running Homebrew installer..."
    
    # Configure Homebrew environment variables for current session
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    fi
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi

# Verify Homebrew installation
if ! command -v brew &> /dev/null; then
    error "Homebrew installation failed."
    exit 1
fi

# 4. Install Chezmoi
step 3 4 "Installing Chezmoi..."
if ! command -v chezmoi &> /dev/null; then
    brew install chezmoi > /dev/null 2>&1 &
    spinner $! "Installing Chezmoi via Homebrew..."
    success "Chezmoi installed"
else
    success "Chezmoi already installed"
fi

# 5. Initialize Homeup
step 4 4 "Initializing Homeup..."
if [ -d "$HOME/.local/share/chezmoi" ]; then
    info "Chezmoi directory already exists. Pulling latest changes..."
    chezmoi git pull -- --autostash --rebase > /dev/null 2>&1 &
    spinner $! "Updating Homeup repo..."
    
    info "Applying changes..."
    chezmoi apply
else
    info "Running chezmoi init..."
    if [ -d ".git" ]; then
        info "Detected git repository, initializing from current directory..."
        chezmoi init --apply --source .
    else
        if [ -n "$1" ]; then
             chezmoi init --apply "$1"
        else
             warning "No repository URL provided and not in a git repository."
             echo "Usage: $0 <repo-url>"
             echo "Example: $0 https://github.com/username/homeup.git"
             exit 1
        fi
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✨ Bootstrap Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


log_success() {
    echo -e "${GREEN}${ICON_SUCCESS}  $1${NC}"
}

log_success "Bootstrap complete! Please restart your shell."
