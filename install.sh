#!/usr/bin/env bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header "Development Environment Installer"

echo ""
print_step "Making scripts executable..."
chmod +x "$SCRIPT_DIR/apply.sh"
print_success "apply.sh"

for script in "$SCRIPT_DIR/scripts"/*.sh; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        print_success "scripts/$(basename "$script")"
    fi
done

echo ""
print_step "Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)"
print_success "chezmoi installed"

echo ""
print_step "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
print_success "oh-my-zsh installed"

echo ""
print_step "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
print_success "Homebrew installed"

echo ""
print_step "Installing zsh-syntax-highlighting..."
brew install zsh-syntax-highlighting
print_success "zsh-syntax-highlighting installed"

print_header "Installation Complete!"
echo ""
echo -e "  Run ${CYAN}./apply.sh${NC} to apply your dotfiles"
echo ""
