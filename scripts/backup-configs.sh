#!/bin/bash

# Backup existing configurations before installing dotfiles
# This is a safety net to restore previous configs if needed

set -e

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
CONFIGS_TO_BACKUP=(
    ".zshrc"
    ".bashrc"
    ".gitconfig"
    ".npmrc"
    ".vimrc"
    ".tmux.conf"
    ".aliases"
)

echo "📦 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

echo "🔄 Backing up existing configurations..."
for config in "${CONFIGS_TO_BACKUP[@]}"; do
    if [ -f "$HOME/$config" ] || [ -L "$HOME/$config" ]; then
        echo "  Backing up $config"
        cp -L "$HOME/$config" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# Backup .ssh/config if it exists (but not keys!)
if [ -f "$HOME/.ssh/config" ]; then
    echo "  Backing up .ssh/config"
    mkdir -p "$BACKUP_DIR/.ssh"
    cp "$HOME/.ssh/config" "$BACKUP_DIR/.ssh/"
fi

echo "✅ Backup completed in: $BACKUP_DIR"
echo "💡 To restore a config: cp $BACKUP_DIR/.zshrc ~/.zshrc"
