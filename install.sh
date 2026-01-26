#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# Dotfiles Bootstrap - Installs paw and initializes dotfiles
# Run this on a new machine:
#   curl -fsSL https://raw.githubusercontent.com/alexcatdad/dotfiles/main/install.sh | bash
# ══════════════════════════════════════════════════════════════════════════════

set -e

echo "🐱 Setting up dotfiles..."

# Install paw if not present
if ! command -v paw &> /dev/null; then
  echo "→ Installing paw..."
  curl -fsSL https://raw.githubusercontent.com/alexcatdad/paw/main/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
fi

# Initialize with this dotfiles repo
paw init https://github.com/alexcatdad/dotfiles
