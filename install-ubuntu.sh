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
    build-essential \
    zsh \
    jq \
    unzip

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

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Change default shell to zsh
if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
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

# Link Ubuntu-specific configurations
echo "Linking Ubuntu-specific configurations..."
for file in "$DOTFILES_DIR/ubuntu/."*; do
    [ -f "$file" ] && link_file "$file" "$HOME/$(basename "$file")"
done

echo "✅ Ubuntu dotfiles installation complete!"
echo "You may need to restart your terminal or run 'source ~/.bashrc'"