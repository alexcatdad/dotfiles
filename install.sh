#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# PAW - Dotfiles Bootstrap Script
# Run this on a new machine to install the paw CLI:
#   curl -fsSL https://raw.githubusercontent.com/alexcatdad/dotfiles/main/install.sh | bash
#
# After installation, use paw directly:
#   paw install          # Full setup: packages + symlinks
#   paw install --dry-run # Preview changes
#   paw --help           # See all options
# ══════════════════════════════════════════════════════════════════════════════

set -e

REPO="alexcatdad/dotfiles"
INSTALL_DIR="${PAW_REPO:-${DOTFILES_DIR:-$HOME/dotfiles}}"
BIN_DIR="$HOME/.local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}🐱 paw${NC} - dotfiles manager"
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
# Clone or update repository
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
# Create bin directory
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Try to use pre-built binary first
# ─────────────────────────────────────────────────────────────────────────────
BINARY="paw-${OS}-${ARCH}"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${BINARY}"

echo -e "${GREEN}→${NC} Checking for pre-built binary..."
if curl -fsSL "$DOWNLOAD_URL" -o "$BIN_DIR/paw" 2>/dev/null; then
  chmod +x "$BIN_DIR/paw"
  echo -e "${GREEN}✓${NC} Installed paw to $BIN_DIR/paw"
else
  # ─────────────────────────────────────────────────────────────────────────────
  # Fall back to running from source with Bun
  # ─────────────────────────────────────────────────────────────────────────────
  echo -e "${YELLOW}→${NC} No pre-built binary found. Building from source..."

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

  # Build and install paw binary
  echo -e "${GREEN}→${NC} Building paw..."
  bun build src/index.ts --compile --outfile="$BIN_DIR/paw"
  echo -e "${GREEN}✓${NC} Built and installed paw to $BIN_DIR/paw"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Ensure ~/.local/bin is in PATH
# ─────────────────────────────────────────────────────────────────────────────
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo ""
  echo -e "${YELLOW}Note:${NC} $BIN_DIR is not in your PATH"
  echo -e "Add this to your shell config:"
  echo -e "  ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Show next steps
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ Installation complete!${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  ${CYAN}paw install${NC}           # Full setup: packages + symlinks"
echo -e "  ${CYAN}paw install --dry-run${NC} # Preview changes without applying"
echo -e "  ${CYAN}paw link --force${NC}      # Symlinks only"
echo -e "  ${CYAN}paw status${NC}            # Check current state"
echo -e "  ${CYAN}paw --help${NC}            # See all commands and options"
echo ""
echo -e "${BLUE}→${NC} Run ${YELLOW}paw install${NC} to set up your dotfiles"
