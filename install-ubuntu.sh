#!/bin/bash

# Ubuntu Dotfiles Installation Script

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🐧 Installing dotfiles for Ubuntu..."

# Function to create symlink
link_file() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        echo "Removing existing symlink: $dest"
        rm "$dest"
    elif [ -f "$dest" ] || [ -d "$dest" ]; then
        echo "Backing up existing file: $dest -> $dest.backup"
        mv "$dest" "$dest.backup"
    fi

    echo "Linking: $src -> $dest"
    ln -sf "$src" "$dest"
}

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install common development tools
echo "Installing common development tools..."
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    tmux \
    htop \
    tree \
    build-essential

# Link shared configurations
echo "Linking shared configurations..."
for file in "$DOTFILES_DIR/shared/."*; do
    [ -f "$file" ] && link_file "$file" "$HOME/$(basename "$file")"
done

# Link Ubuntu-specific configurations
echo "Linking Ubuntu-specific configurations..."
for file in "$DOTFILES_DIR/ubuntu/."*; do
    [ -f "$file" ] && link_file "$file" "$HOME/$(basename "$file")"
done

echo "✅ Ubuntu dotfiles installation complete!"
echo "You may need to restart your terminal or run 'source ~/.bashrc'"