#!/usr/bin/env bash

set -e

echo "Making scripts executable..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"
for script in "$SCRIPT_DIR"/*.sh; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        echo "  Made executable: scripts/$(basename "$script")"
    fi
done

echo "Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)"
echo "chezmoi installation complete."

echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
echo "oh-my-zsh installation complete."

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo "Homebrew installation complete."

echo "Installing zsh-syntax-highlighting..."
brew install zsh-syntax-highlighting

echo "Done."
