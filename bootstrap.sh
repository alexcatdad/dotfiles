#!/bin/bash

# Complete development environment bootstrap
# Sets up everything from scratch on a new machine

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Bootstrapping development environment..."
echo "This will set up your complete TypeScript development environment"
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "🖥️  Detected: $MACHINE"

# Confirm before proceeding
read -p "Continue with bootstrap? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Bootstrap cancelled"
    exit 1
fi

# Step 1: Install system dependencies
echo ""
echo "📦 Installing system dependencies..."

if [[ "$MACHINE" == "Mac" ]]; then
    # Install Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Please complete Xcode installation and re-run this script"
        exit 1
    fi

    # Install Homebrew
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install Git if not present
    if ! command -v git &> /dev/null; then
        brew install git
    fi

elif [[ "$MACHINE" == "Linux" ]]; then
    # Update package lists
    sudo apt update

    # Install essential packages
    sudo apt install -y curl wget git build-essential software-properties-common
fi

# Step 2: Clone or update dotfiles
echo ""
echo "📁 Setting up dotfiles..."

# If running from a different location, clone the repo
if [[ ! -f "$DOTFILES_DIR/install" ]]; then
    DOTFILES_TARGET="$HOME/dotfiles"
    if [[ ! -d "$DOTFILES_TARGET" ]]; then
        echo "Cloning dotfiles repository..."
        git clone https://github.com/alexalexandrescu/dotfiles.git "$DOTFILES_TARGET"
    fi
    cd "$DOTFILES_TARGET"
    DOTFILES_DIR="$DOTFILES_TARGET"
fi

# Step 3: Initialize dotbot submodule
echo ""
echo "🔧 Setting up dotbot..."
if [[ ! -d "$DOTFILES_DIR/dotbot" ]]; then
    cd "$DOTFILES_DIR"
    git submodule add https://github.com/anishathalye/dotbot dotbot
    git submodule update --init --recursive
fi

# Step 4: Install Oh My Zsh plugins
echo ""
echo "🎨 Setting up Zsh plugins..."

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Install external plugins
plugins=(
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-completions"
)

for plugin in "${plugins[@]}"; do
    plugin_name=$(basename "$plugin")
    if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin_name" ]]; then
        echo "Installing $plugin_name..."
        git clone "https://github.com/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin_name"
    fi
done

# Install Powerlevel10k theme
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# Step 5: Run dotfiles installation
echo ""
echo "🔗 Installing dotfiles..."
cd "$DOTFILES_DIR"
./install

# Step 6: Install development tools
echo ""
echo "🛠️  Installing development tools..."

# Install NVM and Node.js
if [[ ! -d "$HOME/.nvm" ]]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest LTS Node.js
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
fi

# Install Bun
if ! command -v bun &> /dev/null; then
    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
fi

# Install global npm packages
echo "Installing global npm packages..."
npm install -g \
    typescript \
    ts-node \
    @types/node \
    prettier \
    eslint \
    nodemon \
    pm2

# Step 7: Final setup
echo ""
echo "🎯 Final setup..."

# Set Zsh as default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Setting Zsh as default shell..."
    chsh -s $(which zsh)
    echo "⚠️  You'll need to restart your terminal for this to take effect"
fi

# Configure Git if not already done
if [[ -z "$(git config --global user.name)" ]]; then
    echo ""
    echo "📝 Git configuration:"
    read -p "Enter your name: " git_name
    read -p "Enter your email: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
fi

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "🎉 Your development environment is ready!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Configure Powerlevel10k: p10k configure"
echo "3. Start coding! 🚀"
echo ""
echo "💡 Run 'create-ts-project my-app' to create your first TypeScript project"