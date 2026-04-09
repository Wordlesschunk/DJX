# DJX

Personal dev environment configuration managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

```bash
chmod +x install.sh
./install.sh
```

This installs:
- chezmoi (dotfile manager)
- Oh My Zsh
- Homebrew
- Powerlevel10k theme
- zsh-syntax-highlighting

## Structure

```
.
├── configs/        # Shell and tool configurations
├── scripts/        # Utility scripts
├── dot_zshrc       # Main zsh config
└── setup.sh        # Installation script
```

## Configuration

After installation, update `DEV_DIR` in `dot_zshrc` to point to where you cloned this repo:

```bash
export DEV_DIR="$HOME/path/to/this/repo"
```

## Requirements

- macOS (uses Homebrew)
- Zsh shell
- [Nerd Font](https://www.nerdfonts.com/) for Powerlevel10k icons
