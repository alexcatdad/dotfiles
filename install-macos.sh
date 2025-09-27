#!/bin/bash

# macOS Dotfiles Installation Script

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🍎 Installing dotfiles for macOS..."

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

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Link shared configurations
echo "Linking shared configurations..."
for file in "$DOTFILES_DIR/shared/."*; do
    [ -f "$file" ] && link_file "$file" "$HOME/$(basename "$file")"
done

# Link macOS-specific configurations
echo "Linking macOS-specific configurations..."
for file in "$DOTFILES_DIR/macos/."*; do
    [ -f "$file" ] && link_file "$file" "$HOME/$(basename "$file")"
done

echo "✅ macOS dotfiles installation complete!"
echo "You may need to restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc'"