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
    # Add Homebrew to PATH for Apple Silicon Macs
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install packages from Brewfile
if [ -f "$DOTFILES_DIR/macos/Brewfile" ]; then
    echo "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/macos/Brewfile"
fi

# Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install NVM if not present
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
fi

# Install Bun if not present
if ! command -v bun &> /dev/null; then
    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
fi

# Backup existing configurations
if [ -f "$DOTFILES_DIR/scripts/backup-configs.sh" ]; then
    echo "Creating backup of existing configurations..."
    "$DOTFILES_DIR/scripts/backup-configs.sh"
fi

# Link shared configurations
echo "Linking shared configurations..."
for file in "$DOTFILES_DIR/shared/."*; do
    [ -f "$file" ] && link_file "$file" "$HOME/$(basename "$file")"
done

# Set up global gitignore
git config --global core.excludesfile ~/.gitignore_global

# Link macOS-specific configurations
echo "Linking macOS-specific configurations..."
for file in "$DOTFILES_DIR/macos/."*; do
    [ -f "$file" ] && link_file "$file" "$HOME/$(basename "$file")"
done

echo "✅ macOS dotfiles installation complete!"
echo "You may need to restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc'"