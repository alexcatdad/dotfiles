#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# DOTFILES BOOTSTRAP SCRIPT
# Run this on a new machine to set everything up:
#   curl -fsSL https://raw.githubusercontent.com/alexalexandrescu/dotfiles/main/install.sh | bash
# ══════════════════════════════════════════════════════════════════════════════

set -e

REPO="alexalexandrescu/dotfiles"
INSTALL_DIR="${DOTFILES_DIR:-$HOME/Projects/dotfiles}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══ Dotfiles Bootstrap ═══${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Detect platform and architecture
# ─────────────────────────────────────────────────────────────────────────────
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Normalize architecture names
case "$ARCH" in
  x86_64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
esac

echo -e "${GREEN}→${NC} Detected: ${OS}-${ARCH}"

# ─────────────────────────────────────────────────────────────────────────────
# Check for git
# ─────────────────────────────────────────────────────────────────────────────
if ! command -v git &> /dev/null; then
  echo -e "${RED}✗${NC} Git is not installed. Please install git first."
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Clone repository if not exists
# ─────────────────────────────────────────────────────────────────────────────
if [ ! -d "$INSTALL_DIR" ]; then
  echo -e "${GREEN}→${NC} Cloning dotfiles repository..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "https://github.com/${REPO}.git" "$INSTALL_DIR"
else
  echo -e "${GREEN}→${NC} Dotfiles directory exists, pulling latest..."
  cd "$INSTALL_DIR"
  git pull --rebase || true
fi

cd "$INSTALL_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Try to use pre-built binary first
# ─────────────────────────────────────────────────────────────────────────────
BINARY="dotfiles-${OS}-${ARCH}"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${BINARY}"

# Check if release exists
if curl --output /dev/null --silent --head --fail "$DOWNLOAD_URL"; then
  echo -e "${GREEN}→${NC} Downloading pre-built binary..."
  TEMP_BIN=$(mktemp)
  curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_BIN"
  chmod +x "$TEMP_BIN"

  echo -e "${GREEN}→${NC} Running dotfiles installer..."
  "$TEMP_BIN" install "$@"

  rm -f "$TEMP_BIN"
else
  # ─────────────────────────────────────────────────────────────────────────────
  # Fall back to running from source with Bun
  # ─────────────────────────────────────────────────────────────────────────────
  echo -e "${YELLOW}→${NC} No pre-built binary found. Installing from source..."

  # Install Bun if not present
  if ! command -v bun &> /dev/null; then
    echo -e "${GREEN}→${NC} Installing Bun..."
    curl -fsSL https://bun.sh/install | bash

    # Add bun to PATH for this session
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
  fi

  # Install dependencies
  echo -e "${GREEN}→${NC} Installing dependencies..."
  bun install

  # Run the installer
  echo -e "${GREEN}→${NC} Running dotfiles installer..."
  bun run src/index.ts install "$@"
fi

echo ""
echo -e "${GREEN}✓${NC} Setup complete!"
echo -e "${BLUE}→${NC} Restart your shell or run: ${YELLOW}source ~/.zshrc${NC}"
