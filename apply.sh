#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Icons
CHECK="✓"
ARROW="→"

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "${YELLOW}${ARROW}${NC} $1"
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

branch=$(git branch --show-current)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header "DJX Apply"

echo ""
echo -e "  Branch: ${CYAN}${branch}${NC}"
echo ""

print_step "Making scripts executable..."
for script in "$SCRIPT_DIR/scripts"/*.sh; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        print_success "scripts/$(basename "$script")"
    fi
done

echo ""
print_step "Cleaning up existing chezmoi config..."
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
rm -rf ~/.zshrc
print_success "Cleaned up old configs"

echo ""
print_step "Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)"
print_success "chezmoi installed"

echo ""
print_step "Initializing chezmoi..."
bin/chezmoi init --branch "$branch" https://github.com/Wordlesschunk/DJX.git
print_success "chezmoi initialized"

echo ""
print_step "Applying dotfiles..."
bin/chezmoi apply
print_success "Dotfiles applied"

print_header "All Done!"
echo ""
echo -e "${GREEN}Open a new terminal to see applied config${NC}"
echo ""
