#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# PAW - Dotfiles Bootstrap Script
# Run this on a new machine to set everything up:
#   curl -fsSL https://raw.githubusercontent.com/alexcatdad/dotfiles/main/install.sh | bash
#
# Options:
#   --force     Force reinstall even if same version
#   --upgrade   Accept breaking changes during major version upgrade
#   --version   Show version info and exit
# ══════════════════════════════════════════════════════════════════════════════

set -e

REPO="alexcatdad/dotfiles"
INSTALL_DIR="${PAW_REPO:-${DOTFILES_DIR:-$HOME/dotfiles}}"
BIN_DIR="$HOME/.local/bin"
STATE_FILE="$HOME/.paw-version"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse arguments
FORCE=false
UPGRADE=false
SHOW_VERSION=false
PASS_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --upgrade) UPGRADE=true ;;
    --version) SHOW_VERSION=true ;;
    *) PASS_ARGS+=("$arg") ;;
  esac
done

echo -e "${CYAN}🐱 paw${NC} - dotfiles manager"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Version helpers
# ─────────────────────────────────────────────────────────────────────────────
get_installed_version() {
  if [ -f "$BIN_DIR/paw" ]; then
    "$BIN_DIR/paw" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0"
  else
    echo "0.0.0"
  fi
}

get_remote_version() {
  # Try to get version from latest release tag
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
    | grep -oE '"tag_name":\s*"v?([0-9]+\.[0-9]+\.[0-9]+)"' \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \
    || echo "0.0.0"
}

parse_version() {
  local version="$1"
  echo "$version" | tr '.' ' '
}

is_major_upgrade() {
  local current="$1"
  local new="$2"

  local current_major
  local new_major
  current_major=$(echo "$current" | cut -d. -f1)
  new_major=$(echo "$new" | cut -d. -f1)

  [ "$new_major" -gt "$current_major" ]
}

save_version() {
  local version="$1"
  echo "$version" > "$STATE_FILE"
  echo "install_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$STATE_FILE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Show version info
# ─────────────────────────────────────────────────────────────────────────────
if [ "$SHOW_VERSION" = true ]; then
  INSTALLED=$(get_installed_version)
  REMOTE=$(get_remote_version)

  echo -e "${BOLD}Installed:${NC} $INSTALLED"
  echo -e "${BOLD}Latest:${NC}    $REMOTE"

  if [ "$INSTALLED" = "$REMOTE" ]; then
    echo -e "${GREEN}✓${NC} Up to date"
  elif [ "$INSTALLED" = "0.0.0" ]; then
    echo -e "${YELLOW}→${NC} Not installed"
  else
    echo -e "${YELLOW}→${NC} Update available"
  fi
  exit 0
fi

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
# Clone repository if not exists (needed before running paw)
# ─────────────────────────────────────────────────────────────────────────────
ensure_repo() {
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
}

# ─────────────────────────────────────────────────────────────────────────────
# Check versions and handle upgrades
# ─────────────────────────────────────────────────────────────────────────────
INSTALLED_VERSION=$(get_installed_version)
REMOTE_VERSION=$(get_remote_version)

if [ "$INSTALLED_VERSION" != "0.0.0" ]; then
  echo -e "${GREEN}→${NC} Installed version: ${BOLD}$INSTALLED_VERSION${NC}"
  echo -e "${GREEN}→${NC} Latest version:    ${BOLD}$REMOTE_VERSION${NC}"

  # Check if already up to date
  if [ "$INSTALLED_VERSION" = "$REMOTE_VERSION" ] && [ "$FORCE" = false ]; then
    echo -e "${GREEN}✓${NC} Already up to date!"
    echo -e "${BLUE}→${NC} Use ${YELLOW}--force${NC} to reinstall anyway"
    echo ""
    # Ensure repo exists and cd to it before running paw
    ensure_repo
    echo -e "${GREEN}→${NC} Running paw install to sync config..."
    "$BIN_DIR/paw" install "${PASS_ARGS[@]}"
    exit 0
  fi

  # Check for major version upgrade (breaking changes)
  if is_major_upgrade "$INSTALLED_VERSION" "$REMOTE_VERSION"; then
    echo ""
    echo -e "${YELLOW}${BOLD}⚠ MAJOR VERSION UPGRADE${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────────────${NC}"
    echo -e "Upgrading from ${RED}v$INSTALLED_VERSION${NC} to ${GREEN}v$REMOTE_VERSION${NC}"
    echo ""
    echo -e "Major versions may include ${BOLD}breaking changes${NC}:"
    echo -e "  • Config file format changes"
    echo -e "  • Renamed or removed commands"
    echo -e "  • New required dependencies"
    echo ""
    echo -e "See changelog: ${CYAN}https://github.com/${REPO}/releases${NC}"
    echo ""

    if [ "$UPGRADE" = false ]; then
      echo -e "${RED}✗${NC} Use ${YELLOW}--upgrade${NC} to accept breaking changes"
      echo -e "  Example: ${CYAN}curl -fsSL ... | bash -s -- --upgrade${NC}"
      exit 1
    fi

    echo -e "${GREEN}✓${NC} --upgrade flag provided, proceeding..."
    echo ""
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Ensure repo exists and cd to it before installing/upgrading
# ─────────────────────────────────────────────────────────────────────────────
ensure_repo

# ─────────────────────────────────────────────────────────────────────────────
# Create bin directory
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Try to use pre-built binary first
# ─────────────────────────────────────────────────────────────────────────────
BINARY="paw-${OS}-${ARCH}"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${BINARY}"

# Check if release exists
if curl --output /dev/null --silent --head --fail "$DOWNLOAD_URL"; then
  echo -e "${GREEN}→${NC} Downloading pre-built binary..."
  curl -fsSL "$DOWNLOAD_URL" -o "$BIN_DIR/paw"
  chmod +x "$BIN_DIR/paw"
  echo -e "${GREEN}✓${NC} Installed paw to $BIN_DIR/paw"

  # Save version info
  save_version "$REMOTE_VERSION"

  echo -e "${GREEN}→${NC} Running paw install..."
  "$BIN_DIR/paw" install "${PASS_ARGS[@]}"
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

  # Build and install paw binary
  echo -e "${GREEN}→${NC} Building paw..."
  bun build src/index.ts --compile --outfile="$BIN_DIR/paw"
  echo -e "${GREEN}✓${NC} Installed paw to $BIN_DIR/paw"

  # Save version info (from built binary)
  BUILT_VERSION=$("$BIN_DIR/paw" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "dev")
  save_version "$BUILT_VERSION"

  # Run the installer
  echo -e "${GREEN}→${NC} Running paw install..."
  "$BIN_DIR/paw" install "${PASS_ARGS[@]}"
fi

echo ""
echo -e "${GREEN}✓${NC} Setup complete!"
echo -e "${BLUE}→${NC} Restart your shell or run: ${YELLOW}source ~/.zshrc${NC}"
echo -e "${BLUE}→${NC} Then use ${CYAN}paw${NC} to manage your dotfiles"
