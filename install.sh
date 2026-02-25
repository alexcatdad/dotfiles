#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# Dotfiles Bootstrap - Installs paw and initializes dotfiles
# Run this on a new machine:
#   ./install.sh
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

echo "🐱 Setting up dotfiles..."

if ! command -v brew >/dev/null 2>&1; then
  echo "✗ Homebrew is required but not installed."
  echo "  Install Homebrew first: https://brew.sh"
  exit 1
fi

echo "→ Ensuring alexcatdad tap is configured..."
brew tap alexcatdad/tap >/dev/null

# Install paw from the tap if missing.
if ! brew list --formula alexcatdad/tap/paw >/dev/null 2>&1; then
  echo "→ Installing paw from Homebrew tap..."
  brew install alexcatdad/tap/paw
fi

# Verification checks
if ! brew list --formula alexcatdad/tap/paw >/dev/null 2>&1; then
  echo "✗ Homebrew formula alexcatdad/tap/paw is not installed."
  exit 1
fi

if ! command -v paw >/dev/null 2>&1; then
  echo "✗ paw is not available in PATH after Homebrew install."
  exit 1
fi

if ! paw --version >/dev/null 2>&1; then
  echo "✗ paw installed but version check failed."
  exit 1
fi

echo "✓ paw installed: $(paw --version)"

# Initialize with this dotfiles repo
paw init https://github.com/alexcatdad/dotfiles
