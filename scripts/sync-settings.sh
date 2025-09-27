#!/bin/bash

# Sync settings between machines
# Run this periodically to keep your dotfiles in sync

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔄 Syncing dotfiles settings..."

# Pull latest changes from remote
cd "$DOTFILES_DIR"
git pull origin main

# Update system packages
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📦 Updating Homebrew packages..."
    brew update && brew upgrade
    brew bundle --file="$DOTFILES_DIR/macos/Brewfile" --cleanup
elif [[ "$OSTYPE" == "linux"* ]]; then
    echo "📦 Updating APT packages..."
    sudo apt update && sudo apt upgrade -y
fi

# Update Node.js to latest LTS if using NVM
if command -v nvm &> /dev/null; then
    echo "📦 Updating Node.js to latest LTS..."
    nvm install --lts --reinstall-packages-from=current
    nvm alias default lts/*
fi

# Update global npm packages
if command -v npm &> /dev/null; then
    echo "📦 Updating global npm packages..."
    npm update -g
fi

# Update Bun if available
if command -v bun &> /dev/null; then
    echo "📦 Updating Bun..."
    bun upgrade
fi

echo "✅ Sync completed!"
echo "💡 Run 'source ~/.zshrc' to apply any shell changes"