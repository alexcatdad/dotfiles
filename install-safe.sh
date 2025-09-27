#!/bin/bash

# Safe installation for existing systems
# Preserves existing configurations and allows selective installation

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🛡️  Safe installation for existing systems"
echo "This will preserve your existing configurations"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check what's already installed
check_existing() {
    echo "🔍 Checking existing setup..."

    local existing_configs=()
    local configs_to_check=(
        ".zshrc"
        ".gitconfig"
        ".npmrc"
        ".tmux.conf"
        ".aliases"
    )

    for config in "${configs_to_check[@]}"; do
        if [ -f "$HOME/$config" ] || [ -L "$HOME/$config" ]; then
            existing_configs+=("$config")
        fi
    done

    if [ ${#existing_configs[@]} -gt 0 ]; then
        echo -e "${YELLOW}Found existing configurations:${NC}"
        for config in "${existing_configs[@]}"; do
            echo "  - $config"
        done
        echo ""
        echo "💡 These will be backed up before installation"
    else
        echo -e "${GREEN}No conflicting configurations found${NC}"
    fi
}

# Interactive installation options
interactive_install() {
    echo "📋 Installation Options:"
    echo ""

    # Ask about shell configuration
    echo -n "Install shell configuration (.zshrc, aliases)? [y/N]: "
    read -r install_shell

    # Ask about git configuration
    echo -n "Install git configuration (.gitconfig)? [y/N]: "
    read -r install_git

    # Ask about development tools
    echo -n "Install development tools (npm, tmux configs)? [y/N]: "
    read -r install_dev

    # Ask about modern CLI tools
    echo -n "Install modern CLI tools (bat, exa, fzf, etc.)? [y/N]: "
    read -r install_modern

    # Ask about optional tools
    echo -n "Install optional tools (lazygit, httpie, etc.)? [y/N]: "
    read -r install_optional

    echo ""
}

# Selective package installation
install_packages_selective() {
    local categories=()

    if [[ "$install_modern" =~ ^[Yy]$ ]]; then
        categories+=("modern_cli")
    fi

    if [[ "$install_dev" =~ ^[Yy]$ ]]; then
        categories+=("development" "typescript" "developer_tools")
    fi

    if [[ "$install_optional" =~ ^[Yy]$ ]]; then
        categories+=("optional")
    fi

    if [ ${#categories[@]} -gt 0 ]; then
        echo "📦 Installing selected packages..."
        if [[ "$install_optional" =~ ^[Yy]$ ]]; then
            "$DOTFILES_DIR/scripts/install-packages.sh" --optional "${categories[@]}"
        else
            "$DOTFILES_DIR/scripts/install-packages.sh" "${categories[@]}"
        fi
    fi
}

# Selective configuration linking
link_configs_selective() {
    echo "🔗 Linking selected configurations..."

    # Backup function
    backup_and_link() {
        local src="$1"
        local dest="$2"
        local description="$3"

        if [ -f "$dest" ] || [ -L "$dest" ]; then
            echo "  📦 Backing up existing $description"
            cp -L "$dest" "$dest.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
        fi

        echo "  🔗 Linking $description"
        ln -sf "$src" "$dest"
    }

    # Shell configurations
    if [[ "$install_shell" =~ ^[Yy]$ ]]; then
        backup_and_link "$DOTFILES_DIR/shared/.zshrc" "$HOME/.zshrc" "shell configuration"
        backup_and_link "$DOTFILES_DIR/shared/.aliases" "$HOME/.aliases" "aliases"
        backup_and_link "$DOTFILES_DIR/shared/.modern-aliases" "$HOME/.modern-aliases" "modern aliases"
        backup_and_link "$DOTFILES_DIR/shared/.dev-automations" "$HOME/.dev-automations" "dev automations"
        backup_and_link "$DOTFILES_DIR/shared/.env-detection" "$HOME/.env-detection" "environment detection"

        # Platform-specific
        if [[ "$OSTYPE" == "darwin"* ]]; then
            backup_and_link "$DOTFILES_DIR/macos/.zshrc.local" "$HOME/.zshrc.local" "macOS shell config"
        elif [[ "$OSTYPE" == "linux"* ]]; then
            backup_and_link "$DOTFILES_DIR/ubuntu/.zshrc.local" "$HOME/.zshrc.local" "Ubuntu shell config"
        fi
    fi

    # Git configuration
    if [[ "$install_git" =~ ^[Yy]$ ]]; then
        backup_and_link "$DOTFILES_DIR/shared/.gitconfig" "$HOME/.gitconfig" "git configuration"
        backup_and_link "$DOTFILES_DIR/shared/.gitignore_global" "$HOME/.gitignore_global" "global gitignore"
        git config --global core.excludesfile ~/.gitignore_global
    fi

    # Development tools
    if [[ "$install_dev" =~ ^[Yy]$ ]]; then
        backup_and_link "$DOTFILES_DIR/shared/.npmrc" "$HOME/.npmrc" "npm configuration"
        backup_and_link "$DOTFILES_DIR/shared/.nvmrc" "$HOME/.nvmrc" "nvm configuration"
        backup_and_link "$DOTFILES_DIR/shared/.tmux.conf" "$HOME/.tmux.conf" "tmux configuration"
        backup_and_link "$DOTFILES_DIR/shared/.microrc" "$HOME/.config/micro/settings.json" "micro editor config"

        # Create micro config directory if needed
        mkdir -p "$HOME/.config/micro"
    fi
}

# Main installation flow
main() {
    check_existing
    interactive_install

    echo ""
    echo "🚀 Starting selective installation..."
    echo ""

    # Create backup directory
    backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    echo "📁 Backup directory: $backup_dir"
    echo ""

    # Install packages
    install_packages_selective

    # Link configurations
    link_configs_selective

    echo ""
    echo -e "${GREEN}✅ Safe installation complete!${NC}"
    echo ""
    echo "📝 Next steps:"

    if [[ "$install_shell" =~ ^[Yy]$ ]]; then
        echo "  1. Restart your terminal or run: source ~/.zshrc"
    fi

    if [[ "$install_git" =~ ^[Yy]$ ]]; then
        echo "  2. Update git credentials: git config --global user.name 'Your Name'"
        echo "     git config --global user.email 'your.email@example.com'"
    fi

    echo "  3. Test your setup: $DOTFILES_DIR/test/test-dotfiles.sh"
    echo ""
    echo "💡 Your original configs are backed up with .backup.TIMESTAMP extensions"
    echo "💡 You can always run this script again to install more components"
}

# Run main function
main "$@"