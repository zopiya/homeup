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
